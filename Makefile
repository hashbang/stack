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

include $(PWD)/images/build.mk
include $(PWD)/tools/build.mk
include $(PWD)/config/config.env

export PATH := $(PWD)/tools:$(PATH)

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

#TODO: Figure out how to dynamically generate this list
.PHONY: tools
tools: tools/k3s tools/k3d tools/k9s tools/sops tools/ksops-exec tools/kubectl tools/terraform tools/terraform-provider-kustomization

.PHONY: stack
stack: tools registry registry-push
ifeq ($(BACKEND),local)
	k3d cluster create $(NAME) \
		--volume $(PWD)/config/registries.yaml:/etc/rancher/k3s/registries.yaml \
		-p "2321:8080@loadbalancer" \
		-p "2322:8081@loadbalancer"
	k3d kubeconfig merge $(NAME) --switch-context
	kubectl kustomize pods/health | kubectl apply -f -
	kubectl kustomize pods/gitea | kubectl apply -f -
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
