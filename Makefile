DOCKER ?= $(shell command -v docker 2>/dev/null || echo /usr/local/bin/docker)
DOCKER_COMPOSE ?= $(strip $(shell if $(DOCKER) compose version >/dev/null 2>&1; then echo "$(DOCKER) compose"; elif command -v docker-compose >/dev/null 2>&1; then command -v docker-compose; fi))
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

.PHONY: docker-ready docker-build docker-smoke docker-smoke-% docker-dry docker-dry-% docker-install docker-install-% docker-shell-% docker-dev-shell docker-dev-shell-rebuild docker-dev-shell-internal docker-down docker-clean test-brew

docker-ready:
	@unset DOCKER_HOST; $(DOCKER) context use default >/dev/null 2>&1 || true
	@unset DOCKER_HOST; $(DOCKER) info >/dev/null 2>&1 || { \
		echo "❌ Docker not running or socket not accessible. Start Docker Desktop and retry." >&2; \
		exit 1; \
	}
	@if [ -z "$(DOCKER_COMPOSE)" ]; then \
		echo "❌ Docker Compose CLI not available. Install the docker compose plugin or docker-compose binary."; \
		exit 1; \
	fi

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

docker-dev-shell: docker-ready
	@$(MAKE) docker-dev-shell-internal RUN_REBUILD=0

docker-dev-shell-rebuild: docker-ready
	@$(MAKE) docker-dev-shell-internal RUN_REBUILD=1

docker-dev-shell-internal:
	@echo ">> Launching developer container shell"
	@HOST_UID="$$(id -u)" \
	 HOST_GID="$$(id -g)" \
	 HOME_OVERRIDE=${HOME_OVERRIDE:-/workspace/.home} \
	 SSH_AUTH_SOCK="$${SSH_AUTH_SOCK:-}" \
	 DOCKER_COMPOSE="$(DOCKER_COMPOSE)" \
	 COMPOSE_FILE="$(COMPOSE_FILE)" \
	 DOTFILES_PROFILE="$${DOTFILES_PROFILE:-}" \
	 DOTFILES_TARGET="$${DOTFILES_TARGET:-}" \
	 RUN_REBUILD="$(RUN_REBUILD)" \
	 bash -c 'set -euo pipefail; \
extra_args=( "-e" "HOST_UID=$$HOST_UID" "-e" "HOST_GID=$$HOST_GID" "-e" "HOME_OVERRIDE=$$HOME_OVERRIDE" ); \
if [ -S "$$SSH_AUTH_SOCK" ]; then \
  extra_args+=("-e" "SSH_AUTH_SOCK=/ssh-agent" "--volume" "$$SSH_AUTH_SOCK:/ssh-agent"); \
fi; \
if [ -f "$${HOME}/.gitconfig" ]; then \
  extra_args+=("--volume" "$${HOME}/.gitconfig:/workspace/.home/.gitconfig:ro"); \
fi; \
if [ -f "$${HOME}/.ssh/known_hosts" ]; then \
  extra_args+=("--volume" "$${HOME}/.ssh/known_hosts:/workspace/.home/.ssh/known_hosts:ro"); \
fi; \
if [ "$$RUN_REBUILD" = "1" ]; then \
  echo ">> Rebuilding dev image (no cache)"; \
  $$DOCKER_COMPOSE -f $$COMPOSE_FILE build --pull --no-cache dev; \
fi; \
DOTFILES_PROFILE=$$DOTFILES_PROFILE DOTFILES_TARGET=$$DOTFILES_TARGET \
$$DOCKER_COMPOSE -f $$COMPOSE_FILE run --rm \
  -e DOTFILES_PROFILE \
  -e DOTFILES_TARGET \
  "$${extra_args[@]}" \
  dev'

docker-down: docker-ready
	@echo ">> Stopping and removing containers"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down --remove-orphans

docker-clean: docker-ready
	@echo ">> Removing dangling Docker resources for this project"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down --volumes --remove-orphans

test-brew:
	@echo ">> Running macOS bootstrap stubs"
	./test/macos.sh stub
