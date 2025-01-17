GOLANG_VERSION := 1.23.2
ALPINE_VERSION := 3.20

GIT_REPO := github.com/michalswi/shell-executor
DOCKER_REPO := michalsw
APPNAME := shell-executor
VERSION ?= 0.1.0
SERVER_PORT ?= 8080

.DEFAULT_GOAL := help
.PHONY: go-run go-build docker-build docker-run docker-stop

help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ \
	{ printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

go-run: ## Run go
	SERVER_PORT=8080 go run .

go-build: ## Build binary
	CGO_ENABLED=0 \
	go build \
	-v \
	-ldflags "-s -w -X '$(GIT_REPO)/version.AppVersion=$(VERSION)'" \
	-o $(APPNAME)-$(VERSION) .

docker-build: ## Build docker image
	docker build \
	--pull \
	--build-arg GOLANG_VERSION="$(GOLANG_VERSION)" \
	--build-arg ALPINE_VERSION="$(ALPINE_VERSION)" \
	--build-arg APPNAME="$(APPNAME)" \
	--build-arg VERSION="$(VERSION)" \
	--label="build.version=$(VERSION)" \
	--tag="$(DOCKER_REPO)/$(APPNAME):latest" \
	.

docker-run: ## Run docker image
	docker run -d --rm \
	--name $(APPNAME) \
	-p $(SERVER_PORT):$(SERVER_PORT) \
	$(DOCKER_REPO)/$(APPNAME):latest && \
	docker ps

docker-stop: ## Stop running docker
	docker stop $(APPNAME)
