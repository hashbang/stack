.PHONY: update-base
update-base:
	docker run \
		--tty \
		--volume $(PWD)/images/stack-base/files/usr/local/bin/:/usr/local/bin/ \
		--volume $(PWD)/images/stack-base/files/etc/apt/packages.list:/etc/apt/packages.list \
		--volume $(PWD)/images/stack-base/files/etc/apt/sources.list:/etc/apt/sources.list \
		debian:buster \
		/usr/local/bin/update-packages

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

images/git.tar: images/git images/stack-base.tar
	docker load -i images/stack-base.tar
	docker build \
		--tag $(REGISTRY)/git \
		--cache-from $(REGISTRY)/stack-base \
		--build-arg FROM=$(REGISTRY)/stack-base \
		--build-arg REF="$(GIT_REF)" \
		--build-arg URL="$(GIT_URL)" \
		$<
	#'--output type=tar,dest=$@' should work, but is broken
	docker save "$(REGISTRY)/git" -o "$@"

images/gitea.tar: images/gitea images/stack-go.tar images/git.tar
	docker load -i images/stack-go.tar
	docker load -i images/git.tar
	docker build \
		--tag $(REGISTRY)/gitea \
		--cache-from $(REGISTRY)/stack-go \
		--build-arg GIT_FROM=$(REGISTRY)/git \
		--build-arg BUILD_FROM=$(REGISTRY)/stack-go \
		--build-arg REF="$(GITEA_REF)" \
		--build-arg URL="$(GITEA_URL)" \
		$<
	#'--output type=tar,dest=$@' should work, but is broken
	docker save "$(REGISTRY)/gitea" -o "$@"
