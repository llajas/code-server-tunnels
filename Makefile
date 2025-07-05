# --------- configurable bits ----------
REGISTRY ?= registry.lajas.tech
REPO     ?= vscode-tunnel
TAG      := $(shell git describe --tags --always)

# --------- derived names --------------
IMG_SHA  := $(REGISTRY)/$(REPO):$(TAG)     # e.g. registry.lajas.tech/vscode-tunnel:7dd16fc
IMG_LATEST := $(REGISTRY)/$(REPO):latest

# fall back to Dockerfile if no Containerfile
ifeq ($(wildcard Containerfile),)
  BUILD_FILE := Dockerfile
else
  BUILD_FILE := Containerfile
endif

# --------------------------------------
.PHONY: all build push

all: build push

build:
	# build once, stamp it with both tags in a single command
	docker build \
	  -f $(BUILD_FILE) \
	  -t $(IMG_SHA) \
	  -t $(IMG_LATEST) .

push:
	# push the Git-specific tag
	docker push $(IMG_SHA)
	# push the floating 'latest' tag
	docker push $(IMG_LATEST)
