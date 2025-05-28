REGISTRY ?= docker.io/brimdor
REPO ?= vscode-tunnel
TAG := $(shell git describe --tags --always --dirty)
IMG := $(REGISTRY)/$(REPO):$(TAG)

ifeq ($(wildcard Containerfile),)
  Dockerfile := Dockerfile
else
  Dockerfile := Containerfile
endif

all: build push
.PHONY: all build push

build:
        podman build -t $(IMG) . -f $(Dockerfile)

push:
        podman push $(IMG)
