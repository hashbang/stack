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

include $(PWD)/make/*.mk
include $(PWD)/config/config.env

export PATH := $(PWD)/tools:$(PATH)

.PHONY: all
all: stack

.PHONY: clean
clean: clean-stack
	rm -rf tools/*
	rm -rf images/*.tar

.PHONY: mrproper
mrproper: clean clean-stack-mrproper
	rm -rf .cache
