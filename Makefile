default: all

.PHONY: all
all: tools

.PHONY: clean
clean:
	rm -rf out

.PHONY: tools
tools: out/bin/sops out/bin/kind

out/bin/sops: src/sops/Dockerfile
	$(call build,sops,https://github.com/mozilla/sops,v3.6.1,$<)

out/bin/kind: src/kind/Dockerfile
	$(call build,kind,https://github.com/kubernetes-sigs/kind,v0.9.0,$<)

export DOCKER_BUILDKIT = 1

define build
	mkdir -p out/bin/
	docker build \
		-t "local/$(1)-$(3)" \
		--build-arg BIN=$(1) \
		--build-arg URL=$(2) \
		--build-arg REF=$(3) \
		- < "$(PWD)/$(4)" \
	&& docker save local/$(1)-$(3) \
		| tar -xf - -O "$(shell \
			docker save local/$(1)-$(3) \
				| tar -tf - \
			| grep layer.tar \
		)" | tar -xf - $(1) -O > out/bin/$(1) \
	&& chmod +x out/bin/$(1)
endef
