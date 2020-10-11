default: all
BACKEND := local-k3d
NAME := hashbang-stack

# Packages
K3S_REF=v1.19.2+k3s1
K3S_URL=https://github.com/rancher/k3s

K3D_REF=v3.1.3
K3D_URL=https://github.com/rancher/k3d

SOPS_REF=v3.6.1
SOPS_URL=https://github.com/mozilla/sops
SOPS_PKG=go.mozilla.org/sops/v3/cmd/sops

KSOPS_REF=v2.2.0
KSOPS_URL=https://github.com/viaduct-ai/kustomize-sops

KIND_REF=v0.9.0
KIND_URL=https://github.com/kubernetes-sigs/kind

KUBECTL_REF=v1.19.2
KUBECTL_URL=https://github.com/kubernetes/kubernetes
KUBECTL_PKG=k8s.io/kubernetes/cmd/kubectl

TERRAFORM_REF=v0.13.4
TERRAFORM_URL=https://github.com/hashicorp/terraform
TERRAFORM_PKG=github.com/hashicorp/terraform

export PATH := build/bin:$(PATH)

.PHONY: all
all: stack

.PHONY: clean
clean:
ifeq ($(BACKEND),local-kind)
	kind delete cluster --name $(NAME) ||:
else ifeq ($(BACKEND),local-k3d)
	k3d cluster delete $(NAME) ||:
endif
	rm -rf build/bin

.PHONY: mrproper
mrproper: clean
	rm -rf build
	docker rm -f $(NAME)-build ||:
	docker rm -f $(NAME)-shell ||:

.PHONY: stack
stack: tools
ifeq ($(BACKEND),local-kind)
	kind create cluster --name $(NAME)
else ifeq ($(BACKEND),local-k3d)
	k3d cluster create $(NAME)
endif

.PHONY: shell
shell: tools build/images/shell
	docker run \
		-it \
		--env UID="$(shell id -u)" \
		--env GID="$(shell id -g)" \
		--env USER="${USER}" \
		--volume $(PWD):${HOME} \
		--privileged \
		--hostname "$(NAME)" \
		-v /var/run/docker.sock:/var/run/docker.sock \
		"local/$(NAME)-shell" /bin/bash

build/images/shell: src/Dockerfile.shell
	docker build -t "local/$(NAME)-shell" -f "$<" .
	mkdir -p build/images
	touch build/images/shell

.PHONY: tools
tools: build/bin/sops build/bin/kind build/bin/kubectl build/bin/terraform build/bin/ksops-exec build/bin/k3s build/bin/k3d

build/bin/k3s: src/Dockerfile.build
	$(eval CMD="mkdir -p build/data && ./scripts/download && go generate && make && cp dist/artifacts/k3s ../out/")
	$(call build,k3s,"$(K3S_URL)","$(K3S_REF)","$(CMD)",$<)

build/bin/k3d: src/Dockerfile.build
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/k3d")
	$(call build,k3d,"$(K3D_URL)","$(K3D_REF)","$(CMD)",$<)

build/bin/kind: src/Dockerfile.build
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/kind")
	$(call build,kind,"$(KIND_URL)","$(KIND_REF)","$(CMD)",$<)

build/bin/sops: src/Dockerfile.build
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/sops $(SOPS_PKG)")
	$(call build,sops,"$(SOPS_URL)","$(SOPS_REF)","$(CMD)",$<)

build/bin/ksops-exec: src/Dockerfile.build
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/ksops-exec")
	$(call build,ksops,"$(KSOPS_URL)","$(KSOPS_REF)","$(CMD)",$<)

build/bin/kubectl: src/Dockerfile.build
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/kubectl $(KUBECTL_PKG)")
	$(call build,kubectl,"$(KUBECTL_URL)","$(KUBECTL_REF)","$(CMD)",$<)

build/bin/terraform: src/Dockerfile.build
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/terraform $(TERRAFORM_PKG)")
	$(call build,terraform,"$(TERRAFORM_URL)","$(TERRAFORM_REF)","$(CMD)",$<)

export DOCKER_BUILDKIT = 1

define build
	mkdir -p $(PWD)/build/bin
	mkdir -p $(PWD)/build/$(1)
	docker build \
	    -t "local/$(NAME)-build" \
	    -f "$(PWD)/$(5)" \
	    . \
	&& docker run -it \
		--env URL="$(2)" \
		--env REF="$(3)" \
		--env CMD="$(4)" \
		--env UID="$(shell id -u)" \
		--env GID="$(shell id -g)" \
		--privileged \
		-v $(PWD)/build/$(1):/home/build/src \
		-v $(PWD)/build/bin/:/home/build/out \
		-v /var/run/docker.sock:/var/run/docker.sock \
		"local/$(NAME)-build" \
		build \
	&& chmod +x build/bin/*
endef
