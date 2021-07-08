#TODO: Figure out how to dynamically generate this list
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

## Note: --user root, privileged, and the docker socket are all required as
## some builds (k3s) use docker/dapper to build some components
## If anyone can find a nice way to avoid this, we could build unprivileged
define build
	mkdir -p .cache
	docker load -i images/stack-go.tar
	docker run \
		--interactive \
		--tty \
		--rm \
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
