NAME := hashbang
BACKEND := local

export PATH := $(PWD)/tools:$(PATH)

include $(PWD)/config/config.env
include $(PWD)/make/images.mk
include $(PWD)/make/tools.mk

ifeq ($(BACKEND),local)
REGISTRY := registry.localhost:5000
include $(PWD)/make/stack-local.mk
endif

.DEFAULT_GOAL := all
default: all

.PHONY: all
all: stack

.PHONY: clean
clean: clean-stack
	rm -rf tools/*
	rm -rf images/*.tar

.PHONY: mrproper
mrproper: clean clean-stack-mrproper
	rm -rf .cache
