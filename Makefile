REGISTRY ?= registry.lajas.tech
REPO ?= vscode-tunnel
TAG := $(shell git describe --tags --always --dirty)
IMG := $(REGISTRY)/$(REPO):$(TAG)

ifeq ($(wildcard Containerfile),)
  Dockerfile := Dockerfile
else
  Dockerfile := Containerfile
endif

.PHONY: all build push

all: build push

build:
	docker build -t $(IMG) . -f $(Dockerfile)

push:
	docker push $(IMG)
