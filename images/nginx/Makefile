NAME := $(shell basename $(CURDIR))
IMAGE := local/$(NAME):latest
GIT_EPOCH := $(shell git log -1 --format=%at config.env)
GIT_DATETIME := \
        $(shell git log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M:%S' config.env)
.DEFAULT_GOAL := all
-include $(PWD)/config.env

.PHONY: all
all: build

.PHONY: build
build:
	DOCKER_BUILDKIT=1 \
	docker build \
		--build-arg DEBIAN_IMAGE_HASH \
		--build-arg VERSION \
		--build-arg PCRE_VERSION \
		--build-arg PCRE_HASH \
		--tag $(IMAGE) \
		$(PWD)

.PHONY: clean
clean:
	docker image rm -f $(IMAGE)

.PHONY: update-packages
update-packages:
	docker rm -f "$(NAME)-update-packages" || :
	docker run \
		--rm \
		--detach \
		--env GIT_EPOCH="$(GIT_EPOCH)" \
		--name "$(NAME)-update-packages" \
		--user $(shell id -u):$(shell id -g) \
		--volume $(PWD)/files/etc/apt/packages.list:/etc/apt/packages-old.list \
		--volume $(PWD)/files/usr/local/bin:/usr/local/bin \
		debian \
		tail -f /dev/null
	docker exec -it --user=root "$(NAME)" apt-install
	docker exec -it --user=root "$(NAME)" update-packages
	docker cp \
		"$(NAME):/etc/apt/packages.list" \
		"$(PWD)/files/etc/apt/packages.list"
	docker cp \
		"$(NAME):/etc/apt/sources.list" \
		"$(PWD)/files/etc/apt/sources.list"
	docker rm -f "$(NAME)-update-packages"
