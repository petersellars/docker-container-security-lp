include make_env

NS ?= enoviti
VERSION ?= latest

IMAGE_NAME ?= hugo-builder
CONTAINER_NAME ?= hugo-builder
CONTAINER_INSTANCE ?= default

default: build

clean:
	docker rm -f $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) 2> /dev/null || true
	rm -rf ./public ./archetypes

analyze: Dockerfile
	@echo "Analyzing Dockerfile using Hadolint..."
	@docker run --rm -i hadolint/hadolint hadolint --ignore DL3018 - < Dockerfile

build: analyze
	@echo "Building Hugo Builder container..."
	@docker build -t $(NS)/$(CONTAINER_NAME):$(VERSION) .
	@echo "Hugo Builder container built!"
	@docker images $(NS)/$(CONTAINER_NAME):$(VERSION)

build-site: build
	@echo "Build OrgDoc Site..."
	@docker run --rm --name $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) -it $(PORTS) $(VOLUMES) $(ENV) -u hugo $(NS)/$(IMAGE_NAME):$(VERSION) hugo

start: build-site
	@echo "Serving OrgDoc Site..."
	@docker run --rm --name $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) -it $(PORTS) $(VOLUMES) $(ENV) -u hugo $(NS)/$(IMAGE_NAME):$(VERSION) hugo server -w --bind=0.0.0.0

stop:
	@echo "Stop serving OrgDoc Site..."
	@docker stop $(CONTAINER_NAME)-$(CONTAINER_INSTANCE)

check-health:
	@echo "Checking the health of the Hugo Server..."
	@docker inspect --format='{{json .State.Health}}' $(CONTAINER_NAME)-$(CONTAINER_INSTANCE)

push:
	@echo "Pushing docker image to Docker registry..."
	@docker push $(NS)/$(IMAGE_NAME):$(VERSION)

release: build
	@make push -e VERSION=$(VERSION)

.PHONY: clean analyze build build-site start stop check-health push release
