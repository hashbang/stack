.PHONY: update-packages
update-packages:
	docker rm -f "$(NAME)-update-packages" || :
	docker run \
		--rm \
		--detach \
		--env GIT_EPOCH="$(GIT_EPOCH)" \
		--name "$(NAME)-update-packages" \
		--user $(shell id -u):$(shell id -g) \
		--volume $(PWD)/files/etc/apt/packages.list:/etc/apt/packages.list \
		--volume $(PWD)/files/usr/local/bin:/usr/local/bin \
		debian \
		tail -f /dev/null
	docker exec -it --user=root "$(NAME)-update-packages" apt-install
	docker exec -it --user=root "$(NAME)-update-packages" update-packages
	docker cp \
		"$(NAME)-update-packages:/etc/apt/packages.list" \
		"$(PWD)/files/etc/apt/packages.list"
	docker cp \
		"$(NAME)-update-packages:/etc/apt/sources.list" \
		"$(PWD)/files/etc/apt/sources.list"
	docker rm -f "$(NAME)-update-packages"
