DOCKER ?= $(shell command -v docker 2>/dev/null || echo /usr/local/bin/docker)
DOCKER_COMPOSE ?= $(DOCKER) compose
COMPOSE_FILE := docker/docker-compose.yml
DOCKER_SERVICES := ubuntu fedora

define RUN_SMOKE
	@echo ">> Running smoke ($(2)) in $(1)"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) run --pull always --build --rm \
		-w /workspace \
		-e DOTFILES_PROFILE \
		-e DOTFILES_TARGET \
		$(1) bash -lc 'set -euo pipefail; ./test/smoke.sh $(2)'
endef

.PHONY: docker-ready docker-build docker-smoke docker-smoke-% docker-dry docker-dry-% docker-install docker-install-% docker-shell-% docker-down docker-clean test-brew

docker-ready:
	@unset DOCKER_HOST; $(DOCKER) context use default >/dev/null 2>&1 || true
	@unset DOCKER_HOST; $(DOCKER) info >/dev/null 2>&1 || { \
		echo "❌ Docker not running or socket not accessible. Start Docker Desktop and retry." >&2; \
		exit 1; \
	}

docker-build: docker-ready
	@echo ">> Building Docker images ($(DOCKER_SERVICES))"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) build --pull $(DOCKER_SERVICES)

docker-smoke: docker-ready $(addprefix docker-smoke-,$(DOCKER_SERVICES))

docker-smoke-%: docker-ready
	$(call RUN_SMOKE,$*,dry)

docker-dry: docker-ready $(addprefix docker-dry-,$(DOCKER_SERVICES))

docker-dry-%: docker-ready
	$(call RUN_SMOKE,$*,dry)

docker-install: docker-ready $(addprefix docker-install-,$(DOCKER_SERVICES))

docker-install-%: docker-ready
	$(call RUN_SMOKE,$*,real)

docker-shell-%: docker-ready
	@echo ">> Opening interactive shell in $*"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) run --rm \
		-e DOTFILES_PROFILE \
		-e DOTFILES_TARGET \
		-w /workspace \
		$* bash -l

docker-down: docker-ready
	@echo ">> Stopping and removing containers"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down --remove-orphans

docker-clean: docker-ready
	@echo ">> Removing dangling Docker resources for this project"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down --volumes --remove-orphans

test-brew:
	@echo ">> Running macOS bootstrap stubs"
	./test/macos.sh stub
