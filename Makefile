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

clair-down:
	-docker kill clairdb 
	-docker kill clair 
	-docker rm clairdb
	-docker rm clair
	-docker network remove clairnet 
	
clair-up:
	@echo "Starting Clair server..."
	@docker network create clairnet 
	@docker run -d --name clairdb --net=clairnet -e POSTGRES_PASSWORD=password postgres:9.6 
	@sleep 5
	@docker run --net=clairnet --name clair -d -p 6060-6061:6060-6061 -v $(PWD)/clair_config:/config quay.io/coreos/clair:latest -config=/config/config.yaml
	@sleep 5
	@echo "Clair Server is up!"

analyze: Dockerfile
	@echo "Analyzing Dockerfile using Hadolint..."
	@docker run --rm -i hadolint/hadolint hadolint --ignore DL3018 - < Dockerfile
	@docker run -it --rm -v $(PWD):/root/ projectatomic/dockerfile-lint dockerfile_lint \
		-r /root/policies/security_rules.yml \
		-f /root/Dockerfile
	@echo "Analysis of Dockerfile complete!"

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
