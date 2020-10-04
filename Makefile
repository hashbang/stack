default: all

.PHONY: all
all: tools

.PHONY: clean
clean:
	rm -rf out

.PHONY: tools
tools: out/bin/sops out/bin/kind out/bin/kubectl

out/bin/sops: src/go-build/Dockerfile
	$(call build,sops,https://github.com/mozilla/sops,v3.6.1,go.mozilla.org/sops/v3/cmd/sops,$<)

out/bin/kind: src/go-build/Dockerfile
	$(call build,kind,https://github.com/kubernetes-sigs/kind,v0.9.0,"",$<)

out/bin/kubectl: src/go-build/Dockerfile
	$(call build,kubectl,https://github.com/kubernetes/kubernetes,v1.19.2,k8s.io/kubernetes/cmd/kubectl,$<)


export DOCKER_BUILDKIT = 1

define build
	mkdir -p out/bin/
	docker build \
		-t "local/$(1)-$(3)" \
		--build-arg BIN=$(1) \
		--build-arg URL=$(2) \
		--build-arg REF=$(3) \
		--build-arg PKG=$(4) \
		- < "$(PWD)/$(5)" \
	&& docker save local/$(1)-$(3) \
		| tar -xf - -O "$(shell \
			docker save local/$(1)-$(3) \
				| tar -tf - \
				| grep layer.tar \
		)" | tar -xf - $(1) -O > out/bin/$(1) \
	&& chmod +x out/bin/$(1)
endef
