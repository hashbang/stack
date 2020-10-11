default: all
BACKEND := local-k3s
NAME := hashbang-stack

# Packages
K3S_REF=v1.19.2+k3s1
K3S_URL=https://github.com/rancher/k3s

KSOPS_REF=v2.2.0
KSOPS_URL=https://github.com/viaduct-ai/kustomize-sops

SOPS_REF=v3.6.1
SOPS_URL=https://github.com/mozilla/sops
SOPS_PKG=go.mozilla.org/sops/v3/cmd/sops

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
	kind delete cluster --name $(NAME)
endif
	rm -rf build/bin

.PHONY: mrproper
mrproper: clean
	rm -rf build

.PHONY: stack
stack: tools
ifeq ($(BACKEND),local-kind)
	kind create cluster --name $(NAME)
endif

.PHONY: tools
#tools: out/bin/k3s out/bin/sops out/bin/kind out/bin/kubectl out/bin/terraform
tools: build/bin/k3s build/bin/sops build/bin/kind build/bin/kubectl build/bin/terraform build/bin/ksops-exec

build/bin/k3s: src/go-build/Dockerfile
	$(eval CMD="mkdir -p build/data && ./scripts/download && go generate && make && cp dist/artifacts/k3s ../out/")
	$(call build,k3s,"$(K3S_URL)","$(K3S_REF)","$(CMD)",$<)

build/bin/kind: src/go-build/Dockerfile
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/kind")
	$(call build,kind,"$(KIND_URL)","$(KIND_REF)","$(CMD)",$<)

build/bin/sops: src/go-build/Dockerfile
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/sops $(SOPS_PKG)")
	$(call build,sops,"$(SOPS_URL)","$(SOPS_REF)","$(CMD)",$<)

build/bin/ksops-exec: src/go-build/Dockerfile
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/ksops-exec")
	$(call build,ksops,"$(KSOPS_URL)","$(KSOPS_REF)","$(CMD)",$<)

build/bin/kubectl: src/go-build/Dockerfile
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/kubectl $(KUBECTL_PKG)")
	$(call build,kubectl,"$(KUBECTL_URL)","$(KUBECTL_REF)","$(CMD)",$<)

build/bin/terraform: src/go-build/Dockerfile
	$(eval CMD="go build -v -trimpath -ldflags='-w' -o ~/out/terraform $(TERRAFORM_PKG)")
	$(call build,terraform,"$(TERRAFORM_URL)","$(TERRAFORM_REF)","$(CMD)",$<)

export DOCKER_BUILDKIT = 1

define build
	mkdir -p $(PWD)/build/bin/
	mkdir -p $(PWD)/build/$(1)/
	docker build \
		-t "local/build" \
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
		"local/build" \
	&& chmod +x build/bin/*
endef
