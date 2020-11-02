default: all
BACKEND := local
NAME := hashbang
ifeq ($(BACKEND),local)
REGISTRY := registry.localhost:5000
endif
GIT_EPOCH := $(shell git log -1 --format=%at config/config.env)
GIT_DATETIME := \
	$(shell git log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M:%S' config/config.env)
.DEFAULT_GOAL := all
-include $(PWD)/config/config.env
export PATH := $(PWD)/tools:$(PATH)

## Primary Targets

.PHONY: all
all: stack

.PHONY: clean
clean: clean-stack
	rm -rf tools/*
	rm -rf images/*.tar

.PHONY: clean-stack
clean-stack:
ifeq ($(BACKEND),local)
	k3d cluster delete $(NAME) ||:
	docker rm -f registry.localhost ||:
endif

.PHONY: mrproper
mrproper: clean
	rm -rf .cache
	docker network rm "$(NAME)" ||:
	docker volume rm "$(NAME)-registry" ||:
	docker rm -f $(NAME)-build ||:
	docker rm -f $(NAME)-shell ||:

.PHONY: registry
registry: images/docker-registry.tar
ifeq ($(BACKEND),local)
ifeq ($(shell docker ps | grep "registry.localhost" >/dev/null; echo $$?),1)
	docker network create "k3d-$(NAME)" || :
	docker volume create $(NAME)-registry
	docker load -i images/docker-registry.tar
	docker container run \
		--detach \
		--name "registry.localhost" \
		--hostname "registry.localhost" \
		--network "k3d-$(NAME)" \
		--volume $(NAME)-registry:/data \
		--restart always \
		-p 5000:5000 \
		$(REGISTRY)/registry
endif
endif

.PHONY: registry-push
registry-push: registry images/stack-shell.tar images/nginx.tar images/gitea.tar
ifeq ($(BACKEND),local)
	$(contain) bash -c " \
		docker load -i images/nginx.tar && docker push $(REGISTRY)/nginx; \
		docker load -i images/gitea.tar && docker push $(REGISTRY)/gitea; \
	"
endif

.PHONY: stack
stack: tools registry registry-push
ifeq ($(BACKEND),local)
	k3d cluster create $(NAME) \
		--volume $(PWD)/config/registries.yaml:/etc/rancher/k3s/registries.yaml \
		-p "8080:8080@loadbalancer" # health check
	k3d kubeconfig merge $(NAME) --switch-context
endif

.PHONY: shell
shell: tools images/stack-shell.tar
	docker load -i images/stack-shell.tar
	$(contain)

contain := \
	docker run \
		--rm \
		--tty \
		--name=k3d-$(NAME)-shell \
		--interactive \
		--env UID="$(shell id -u)" \
		--env GID="$(shell id -g)" \
		--env USER="${USER}" \
		--volume $(PWD):${HOME} \
		--privileged \
		--user root \
		--network "k3d-$(NAME)" \
		--hostname "$(NAME)" \
		-v /var/run/docker.sock:/var/run/docker.sock \
		"$(REGISTRY)/stack-shell"

## Images

images/stack-base.tar: images/stack-base
	docker build \
		--tag $(REGISTRY)/stack-base \
		--build-arg DEBIAN_IMAGE_HASH \
		$<
	#'--output type=tar,dest=$@' should work, but is broken
	docker save "$(REGISTRY)/stack-base" -o "$@"

images/stack-go.tar: images/stack-go images/stack-base.tar
	docker load -i images/stack-base.tar
	docker build \
		--tag $(REGISTRY)/stack-go \
		--cache-from $(REGISTRY)/stack-base \
		--build-arg FROM=$(REGISTRY)/stack-base \
		$<
	#'--output type=tar,dest=$@' should work, but is broken
	docker save "$(REGISTRY)/stack-go" -o "$@"

images/stack-shell.tar: images/stack-shell images/stack-base.tar
	docker load -i images/stack-base.tar
	docker build \
		--tag $(REGISTRY)/stack-shell \
		--cache-from $(REGISTRY)/stack-base \
		--build-arg FROM=$(REGISTRY)/stack-base \
		$<
	#'--output type=tar,dest=$@' should work, but is broken
	docker save "$(REGISTRY)/stack-shell" -o "$@"

images/docker-registry.tar: images/docker-registry images/stack-go.tar
	docker load -i images/stack-go.tar
	docker build \
		--tag $(REGISTRY)/registry \
		--cache-from $(REGISTRY)/stack-go \
		--build-arg FROM=$(REGISTRY)/stack-go \
		--build-arg URL="$(DOCKER_REGISTRY_URL)" \
		--build-arg REF="$(DOCKER_REGISTRY_REF)" \
		$<
	#'--output type=tar,dest=$@' should work, but is broken
	docker save "$(REGISTRY)/registry" -o "$@"

images/nginx.tar: images/nginx images/stack-base.tar
	docker load -i images/stack-base.tar
	docker build \
		--tag $(REGISTRY)/nginx \
		--cache-from $(REGISTRY)/stack-base \
		--build-arg FROM=$(REGISTRY)/stack-base \
		--build-arg REF="$(NGINX_REF)" \
		--build-arg PCRE_VERSION="$(NGINX_PCRE_VERSION)" \
		--build-arg PCRE_HASH="$(NGINX_PCRE_HASH)" \
		$<
	#'--output type=tar,dest=$@' should work, but is broken
	docker save "$(REGISTRY)/nginx" -o "$@"

images/gitea.tar: images/gitea images/stack-go.tar
	docker load -i images/stack-go.tar
	docker build \
		--tag $(REGISTRY)/gitea \
		--cache-from $(REGISTRY)/stack-go \
		--build-arg FROM=$(REGISTRY)/stack-go \
		--build-arg REF="$(GITEA_REF)" \
		--build-arg URL="$(GITEA_URL)" \
		$<
	#'--output type=tar,dest=$@' should work, but is broken
	docker save "$(REGISTRY)/gitea" -o "$@"


## Tools

.PHONY: tools
tools: tools/k3s tools/k3d tools/k9s tools/sops tools/ksops-exec tools/kubectl tools/terraform tools/terraform-provider-kustomization

tools/k3s: images/stack-go.tar
	$(eval CMD="mkdir -p build/data && ./scripts/download && go generate && make && cp dist/artifacts/k3s ../out/")
	$(call build,k3s,"$(K3S_URL)","$(K3S_REF)","$(CMD)")

tools/k3d: images/stack-go.tar
	$(eval CMD="make build && cp bin/k3d ../out/")
	$(call build,k3d,"$(K3D_URL)","$(K3D_REF)","$(CMD)")

tools/k9s: images/stack-go.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/k9s")
	$(call build,k9s,"$(K9S_URL)","$(K9S_REF)","$(CMD)")

tools/sops: images/stack-go.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/sops $(SOPS_PKG)")
	$(call build,sops,"$(SOPS_URL)","$(SOPS_REF)","$(CMD)")

tools/ksops-exec: images/stack-go.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/ksops-exec")
	$(call build,ksops,"$(KSOPS_URL)","$(KSOPS_REF)","$(CMD)")

tools/kubectl: images/stack-go.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/kubectl $(KUBECTL_PKG)")
	$(call build,kubectl,"$(KUBECTL_URL)","$(KUBECTL_REF)","$(CMD)")

tools/terraform: images/stack-go.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/terraform $(TERRAFORM_PKG)")
	$(call build,terraform,"$(TERRAFORM_URL)","$(TERRAFORM_REF)","$(CMD)")

tools/terraform-provider-kustomization: images/stack-go.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/terraform-provider-kustomization")
	$(call build,terraform-provider-kustomization,"$(TERRAFORM_KUSTOMIZATION_URL)","$(TERRAFORM_KUSTOMIZATION_REF)","$(CMD)")

# Make Helpers

## Note: --user root, privileged, and the docker socket are all required as
## some builds (k3s) use docker/dapper to build some components
## If anyone can find a nice way to avoid this, we could build unprivileged
define build
	mkdir -p .cache
	docker load -i images/stack-go.tar
	docker run \
		--interactive \
		--tty \
		--env URL="$(2)" \
		--env REF="$(3)" \
		--env CMD="$(4)" \
		--env UID="$(shell id -u)" \
		--env GID="$(shell id -g)" \
		--privileged \
		--user root \
		-v $(PWD)/.cache/$(1):/home/build/src \
		-v $(PWD)/tools/:/home/build/out \
		-v /var/run/docker.sock:/var/run/docker.sock \
		"$(REGISTRY)/stack-go" \
	&& chmod +x $(PWD)/tools/*
endef
