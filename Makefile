# Project variables
PROJECT_NAME ?= todobackend
ORG_NAME ?= 2251985
REPO_NAME ?= todobackend

# Filenames
DEV_COMPOSE_FILE := docker/dev/docker-compose-v2.yml
REL_COMPOSE_FILE := docker/release/docker-compose-v2.yml

# Docker Compose Project Name
REL_PROJECT := $(PROJECT_NAME)$(BUILD_ID)
DEV_PROJECT := $(REL_PROJECT)dev

# Application Service Name - must match Docker Compose release specification application service name
APP_SERVICE_NAME := app

# Build tag experssion can be used to evaluate a shell expression at runtime
BUILD_TAG_EXPRESSION := date -u +%Y%m%d%H%M%S

# Execute shell experssion
BUILD_EXPRESSION := $(shell $(BUILD_TAG_EXPRESSION))

# Build tag - default to BUILD_EXPRESSION if not defined
BUILD_TAG ?= $(BUILD_EXPRESSION)

# Check and Inspect Logic
INSPECT := $$(docker-compose -p $$1 -f $$2 ps -q $$3 | xargs -I ARGS docker inspect -f "{{ .State.ExitCode }}" ARGS)

CHECK := @bash -c '\
		 if [[ $(INSPECT) -ne 0 ]]; \
		 then exit $(INSPECT) ; fi' VALUE

# use these settings to specify a custom Docker registry
DOCKER_REGISTRY ?= docker.io

# WARNING: Set DOCKER_REGISTRY_AUTH to empty for Docker Hub
# Set DOCKER_REGISTRY_AUTH to auth endpoint for private Docker registry
DOCKER_REGISTRY_AUTH ?=

.PHONY: test build release clean tag buildtag login logout publish

	# COMMENTS #
	
	# --pull:: Pulling flag fetch latest parent image from regisetry ,
	# 		   after it next service which are also extends parent image would not need --pull flag to ansure conssistentcy between
	# 		   workflow

	# $$ - means get process id of container id

test:
	${INFO} "Creating cache volume..."
	@ docker volume create --name cache
	${INFO} "Pull lastest images..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) pull
	${INFO} "Building images..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) build --pull test
	${INFO} "Strarting up agent service..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) up agent
	${INFO} "Download and install test requirements and running unit tests..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) up test	
	@ docker cp $$(docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) ps -q test):/reports/. reports
	${CHECK} $(DEV_PROJECT) $(DEV_COMPOSE_FILE) test
	${INFO} "Testing complete" 

build:
	${INFO} "Building images..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) build builder
	${INFO} "Building application artifacts..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) up builder
	${CHECK} $(DEV_PROJECT) $(DEV_COMPOSE_FILE) builder
	${INFO} "Copying artifacts to target folder..."
	@ docker cp $$(docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) ps -q builder):/wheelhouse/. target
	${INFO} "Build complete"

release:
	${INFO} "Pull lastest images..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) pull test
	${INFO} "Building images..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) build app
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) build --pull nginx	
	${INFO} "Strarting up agent service..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) up agent
	${INFO} "Collecting static files..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) run --rm app manage.py collectstatic --no-input 
	${INFO} "Running database migrations..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) run --rm app manage.py migrate --no-input
	${INFO} "Runnig acceptance tests..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) up test
	@ docker cp $$(docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) ps -q test):/reports/. reports
	${CHECK} $(REL_PROJECT) $(REL_COMPOSE_FILE) test
	${INFO} "Accpetance testing complete"

clean:
	${INFO} "Destroying development environment..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) down -v
	${INFO} "Destroying release environment..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) down -v
	${INFO} "Removing dangling images"
	@ docker images -q -f dangling=true -f label=application=$(REPO_NAME) | xargs -I ARGS docker rmi -f ARGS 
	${INFO} "Clean complete"

tag:
	${INFO} "Tagging release image with tags $(TAG_ARGS)..."
	@ $(foreach tag,$(TAG_ARGS), docker tag $(IMAGE_ID) $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME):$(tag);)
	${INFO} "Tagging complete"

buildtag:
	${INFO} "Tagging release image with suffix $(BUILD_TAG) and build tags $(BUILDTAG_ARGS)..."
	@ $(foreach tag,$(BUILDTAG_ARGS), docker tag $(IMAGE_ID) $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME):$(tag).$(BUILD_TAG);)
	${INFO} "Tagging complete"
	
login:
	${INFO} "Logging in to Docker registry $$DOCKER_REGISTRY..."
	@ docker login -u $$DOCKER_USER -p $$DOCKER_PASSWORD $(DOCKER_REGISTRY_AUTH)
	${INFO} "Logged in complete"

logout:
	${INFO} "Logging out to Docker registry $$DOCKER_REGISTRY..."
	@ docker logout
	${INFO} "Logged out complete"

publish:
	${INFO} "Publishing release image $(IMAGE_ID) to $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME)..."
	@ $(foreach tag, $(shell echo $(REPO_EXPR)), docker push $(tag);)
	${INFO} "Publish complete"

# Cosmetics
YELLOW := "\e[1;33m"
NC := "\e[0m"

# Shell Functions
INFO := @bash -c '\
		printf $(YELLOW); \
		echo "=> $$1"; \
		printf $(NC)' VALUE

# Get container id of application service container
APP_CONTAINER_ID := $$(docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) ps -q $(APP_SERVICE_NAME))

# Get image id of application service
IMAGE_ID := $$(docker inspect -f '{{ .Image }}' $(APP_CONTAINER_ID))

# Repository Filter
ifeq ($(DOCKER_REGISTRY), docker.io)
  REPO_FILTER := $(ORG_NAME)/$(REPO_NAME)[^[:space:]|\$$]*
else
  REPO_FILTER := $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME)[^[:space:]|\$$]*
endif

# Introspect repository tags
REPO_EXPR := $$(docker inspect -f '{{range .RepoTags}} {{.}} {{end}}' $(IMAGE_ID) | grep -oh "$(REPO_FILTER)" | xargs)       

# Extract buildtag argument
ifeq (buildtag, $(firstword $(MAKECMDGOALS)))
  BUILDTAG_ARGS := $(wordlist 2, $(words $(MAKECMDGOALS)), $(MAKECMDGOALS))
  ifeq ($(BUILDTAG_ARGS),)
	$(error You must specify a buildtag)
  endif
  $(eval $(BUILDTAG_ARGS):;@:)
endif

# Extract tag argument
ifeq (tag, $(firstword $(MAKECMDGOALS)))
  TAG_ARGS := $(wordlist 2, $(words $(MAKECMDGOALS)), $(MAKECMDGOALS))
  ifeq ($(TAG_ARGS),)
	$(error You must specify a tag)
  endif
  $(eval $(TAG_ARGS):;@:)
endif
	
	
	
