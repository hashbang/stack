default: all
BACKEND := local
NAME := hashbang
ifeq ($(BACKEND),local)
REGISTRY := registry.$(NAME).localhost:5000
endif
export DOCKER_BUILDKIT = 1
export PATH := .local/bin:$(PATH)

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
	rm -rf .local/bin/*
	rm -rf .local/images/*

.PHONY: mrproper
mrproper: clean
	rm -rf .local
	docker rm -f $(NAME)-build ||:
	docker rm -f $(NAME)-shell ||:

.PHONY: registry
registry: .local/images/docker-registry.tar
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
shell: tools .local/images/stack-shell.tar
	$(contain)

contain = \
	docker run \
		--rm \
		--tty \
		--interactive \
		--env UID="$(shell id -u)" \
		--env GID="$(shell id -g)" \
		--env USER="${USER}" \
		--volume $(PWD):${HOME} \
		--privileged \
		--network "$(NAME)" \
		--hostname "$(NAME)" \
		-v /var/run/docker.sock:/var/run/docker.sock \
		"$(REGISTRY)/shell"

## Images

## External Images

.local/images/stack-shell.tar: images/stack-shell/Dockerfile
	docker build -t "$(REGISTRY)/shell" -f "$<" .
	mkdir -p $(@D) && docker save "$(REGISTRY)/shell" -o "$@"

.local/images/stack-build.tar: images/stack-build/Dockerfile
	docker build -t "$(REGISTRY)/build" -f "$<" .
	mkdir -p $(@D) && docker save "$(REGISTRY)/build" -o "$@"

.local/images/docker-registry.tar: images/docker-registry
	cd "$<" && make IMAGE="$(REGISTRY)/registry"
	mkdir -p $(@D) && docker save "$(REGISTRY)/registry" -o "$@"

.local/images/nginx.tar: images/nginx
	cd "$<" && make IMAGE="$(REGISTRY)/nginx"
	docker push $(REGISTRY)/nginx
	mkdir -p $(@D) && docker save "$(REGISTRY)/nginx" -o "$@"

## Tools

.PHONY: tools
tools: .local/bin/k3s .local/bin/k3d .local/bin/k9s .local/bin/sops .local/bin/ksops-exec .local/bin/kubectl .local/bin/terraform

K3S_REF=v1.19.2+k3s1
K3S_URL=https://github.com/rancher/k3s
.local/bin/k3s: .local/images/stack-build.tar
	$(eval CMD="mkdir -p build/data && ./scripts/download && go generate && make && cp dist/artifacts/k3s ../out/")
	$(call build,k3s,"$(K3S_URL)","$(K3S_REF)","$(CMD)")

K3D_REF=v3.1.3
K3D_URL=https://github.com/rancher/k3d
local/bin/k3d: .local/images/stack-build.tar
	$(eval CMD="make build && cp bin/k3d ../out/")
	$(call build,k3d,"$(K3D_URL)","$(K3D_REF)","$(CMD)")

K9S_REF=v0.22.1
K9S_URL=https://github.com/derailed/k9s
.local/bin/k9s: .local/images/stack-build.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/k9s")
	$(call build,k9s,"$(K9S_URL)","$(K9S_REF)","$(CMD)")

SOPS_REF=v3.6.1
SOPS_URL=https://github.com/mozilla/sops
SOPS_PKG=go.mozilla.org/sops/v3/cmd/sops
.local/bin/sops: .local/images/stack-build.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/sops $(SOPS_PKG)")
	$(call build,sops,"$(SOPS_URL)","$(SOPS_REF)","$(CMD)")

KSOPS_REF=v2.2.0
KSOPS_URL=https://github.com/viaduct-ai/kustomize-sops
.local/bin/ksops-exec: .local/images/stack-build.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/ksops-exec")
	$(call build,ksops,"$(KSOPS_URL)","$(KSOPS_REF)","$(CMD)")

KUBECTL_REF=v1.19.2
KUBECTL_URL=https://github.com/kubernetes/kubernetes
KUBECTL_PKG=k8s.io/kubernetes/cmd/kubectl
.local/bin/kubectl: .local/images/stack-build.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/kubectl $(KUBECTL_PKG)")
	$(call build,kubectl,"$(KUBECTL_URL)","$(KUBECTL_REF)","$(CMD)")

TERRAFORM_REF=v0.13.4
TERRAFORM_URL=https://github.com/hashicorp/terraform
TERRAFORM_PKG=github.com/hashicorp/terraform
.local/bin/terraform: .local/images/stack-build.tar
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/terraform $(TERRAFORM_PKG)")
	$(call build,terraform,"$(TERRAFORM_URL)","$(TERRAFORM_REF)","$(CMD)")

define build
	mkdir -p \
		$(PWD)/.local/images \
		$(PWD)/.local/bin \
		$(PWD)/.local/cache/$(1)
	docker run \
		--interactive \
		--tty \
		--env URL="$(2)" \
		--env REF="$(3)" \
		--env CMD="$(4)" \
		--env UID="$(shell id -u)" \
		--env GID="$(shell id -g)" \
		--privileged \
		-v $(PWD)/.local/cache/$(1):/home/build/src \
		-v $(PWD)/.local/bin/:/home/build/out \
		-v /var/run/docker.sock:/var/run/docker.sock \
		"$(REGISTRY)/build" \
		build \
	&& chmod +x .local/bin/*
endef
