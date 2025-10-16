DOCKER_COMPOSE ?= docker compose
COMPOSE_FILE := docker/docker-compose.yml
DOCKER_SERVICES := ubuntu fedora

define RUN_SMOKE
	@echo ">> Running smoke ($(2)) in $(1)"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) run --rm \
		-w /workspace \
		-e DOTFILES_PROFILE \
		-e DOTFILES_TARGET \
		$(1) bash -lc 'set -euo pipefail; ./test/smoke.sh $(2)'
endef

.PHONY: docker-build docker-smoke docker-smoke-% docker-dry docker-dry-% docker-install docker-install-% docker-shell-% docker-down docker-clean

docker-build:
	@echo ">> Building Docker images ($(DOCKER_SERVICES))"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) build $(DOCKER_SERVICES)

docker-smoke: $(addprefix docker-smoke-,$(DOCKER_SERVICES))

docker-smoke-%:
	$(call RUN_SMOKE,$*,dry)

docker-dry: $(addprefix docker-dry-,$(DOCKER_SERVICES))

docker-dry-%:
	$(call RUN_SMOKE,$*,dry)

docker-install: $(addprefix docker-install-,$(DOCKER_SERVICES))

docker-install-%:
	$(call RUN_SMOKE,$*,real)

docker-shell-%:
	@echo ">> Opening interactive shell in $*"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) run --rm \
		-e DOTFILES_PROFILE \
		-e DOTFILES_TARGET \
		-w /workspace \
		$* bash -l

docker-down:
	@echo ">> Stopping and removing containers"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down --remove-orphans

docker-clean:
	@echo ">> Removing dangling Docker resources for this project"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down --volumes --remove-orphans
