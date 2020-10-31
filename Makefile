default: all
BACKEND := local
NAME := hashbang
ifeq ($(BACKEND),local)
REGISTRY := registry.$(NAME).localhost:5000
endif
GIT_EPOCH := $(shell git log -1 --format=%at config.env)
GIT_DATETIME := \
        $(shell git log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M:%S' config.env)
.DEFAULT_GOAL := all
-include $(PWD)/config.env
export PATH := $(PWD)/bin:$(PATH)

## Primary Targets

.PHONY: all
all: stack

.PHONY: clean
clean:
ifeq ($(BACKEND),local)
	k3d cluster delete $(NAME) ||:
endif
ifeq ($(BACKEND),local)
	k3d cluster delete $(NAME) ||:
	docker rm -f $(NAME)-registry
endif
	rm -rf bin
	rm -rf images/*.tar

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
	docker network create "$(NAME)" || :
	docker volume create $(NAME)-registry
	docker container run \
		--detach \
		--name "registry.$(NAME)" \
		--hostname "registry.$(NAME)" \
		--network "$(NAME)" \
		--volume $(NAME)-registry:/data \
		--restart always \
		-p 5000:5000 \
		$(REGISTRY)/registry
endif

.PHONY: stack
stack: tools registry
ifeq ($(BACKEND),local)
	k3d cluster create $(NAME)
	docker network connect k3d-$(NAME) $(NAME)
	k3d kubeconfig merge $(NAME) --switch-context
endif

.PHONY: shell
shell: tools images/stack-shell.tar
	docker load -i images/stack-shell.tar
	docker run \
		--rm \
		--tty \
		--interactive \
		--env UID="$(shell id -u)" \
		--env GID="$(shell id -g)" \
		--env USER="${USER}" \
		--volume $(PWD):${HOME} \
		--privileged \
		--user root \
		--network "$(NAME)" \
		--hostname "$(NAME)" \
		-v /var/run/docker.sock:/var/run/docker.sock \
		"$(NAME)/stack-shell"

## Images

images/stack-base.tar: src/stack-base
	docker build \
		--tag $(NAME)/stack-base \
		--build-arg DEBIAN_IMAGE_HASH \
		$<
	#'--output type=tar,dest=$@' should work, but is broken
	docker save "$(NAME)/stack-base" -o "$@"

images/stack-go.tar: src/stack-go images/stack-base.tar
	docker load -i images/stack-base.tar
	docker build \
		--tag $(NAME)/stack-go \
		--cache-from $(NAME)/stack-base \
		--build-arg FROM=$(NAME)/stack-base \
		$<
	#'--output type=tar,dest=$@' should work, but is broken
	docker save "$(NAME)/stack-go" -o "$@"

images/stack-shell.tar: src/stack-shell images/stack-base.tar
	docker load -i images/stack-base.tar
	docker build \
		--tag $(NAME)/stack-shell \
		--cache-from $(NAME)/stack-base \
		--build-arg FROM=$(NAME)/stack-base \
		$<
	#'--output type=tar,dest=$@' should work, but is broken
	docker save "$(NAME)/stack-shell" -o "$@"

images/docker-registry.tar: src/docker-registry images/stack-go.tar
	docker load -i images/stack-go.tar
	docker build \
		--tag $(NAME)/registry \
		--cache-from $(NAME)/stack-go \
		--build-arg FROM=$(NAME)/stack-go \
		--build-arg URL="$(DOCKER_REGISTRY_URL)" \
		--build-arg REF="$(DOCKER_REGISTRY_REF)" \
		$<
	#'--output type=tar,dest=$@' should work, but is broken
	docker save "$(NAME)/registry" -o "$@"

images/nginx.tar: src/nginx
	cd "$<" && make IMAGE="$(REGISTRY)/nginx"
	docker push $(REGISTRY)/nginx
	mkdir -p $(@D) && docker save "$(REGISTRY)/nginx" -o "$@"

## Tools

.PHONY: tools
tools: bin/k3s bin/k3d bin/k9s bin/sops bin/ksops-exec bin/kubectl bin/terraform

bin/k3s: images/stack-go.tar
	$(eval CMD="mkdir -p build/data && ./scripts/download && go generate && make && cp dist/artifacts/k3s ../out/")
	$(call build,k3s,"$(K3S_URL)","$(K3S_REF)","$(CMD)")

bin/k3d: images/stack-go.tar
	$(eval CMD="make build && cp bin/k3d ../out/")
	$(call build,k3d,"$(K3D_URL)","$(K3D_REF)","$(CMD)")

bin/k9s: images/stack-go.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/k9s")
	$(call build,k9s,"$(K9S_URL)","$(K9S_REF)","$(CMD)")

bin/sops: images/stack-go.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/sops $(SOPS_PKG)")
	$(call build,sops,"$(SOPS_URL)","$(SOPS_REF)","$(CMD)")

bin/ksops-exec: images/stack-go.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/ksops-exec")
	$(call build,ksops,"$(KSOPS_URL)","$(KSOPS_REF)","$(CMD)")

bin/kubectl: images/stack-go.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/kubectl $(KUBECTL_PKG)")
	$(call build,kubectl,"$(KUBECTL_URL)","$(KUBECTL_REF)","$(CMD)")

bin/terraform: images/stack-go.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/terraform $(TERRAFORM_PKG)")
	$(call build,terraform,"$(TERRAFORM_URL)","$(TERRAFORM_REF)","$(CMD)")

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
		-v $(PWD)/bin/:/home/build/out \
		-v /var/run/docker.sock:/var/run/docker.sock \
		"$(NAME)/stack-go" \
	&& chmod +x $(PWD)/bin/*
endef
