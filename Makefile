# =============================================================================
# Makefile - Portfolio Deployment
# =============================================================================
# Usage:
#   make up ENV=dev        # Start dev environment
#   make down ENV=dev      # Stop dev environment
#   make logs ENV=dev      # View logs
# =============================================================================

# Default environment
ENV ?= dev

# Valid environments
VALID_ENV := local dev staging prod

# Check if environment is valid
ifeq ($(filter $(ENV),$(VALID_ENV)),)
$(error Invalid environment: $(ENV). Valid: $(VALID_ENV))
endif

# Docker compose files
DC_FILE := docker-compose.yml
DC_PROFILES := --profile $(ENV)

# Colors
GREEN := $(shell tput setaf 2 2>/dev/null || echo "")
YELLOW := $(shell tput setaf 3 2>/dev/null || echo "")
RESET := $(shell tput sgr0 2>/dev/null || echo "")

# =============================================================================
# Helper Functions
# =============================================================================

define print_status
	@echo "$(GREEN)[$(1)]$(RESET) $(2)"
endef

# =============================================================================
# Secrets Management
# =============================================================================

# =============================================================================
# Docker Compose Commands
# =============================================================================

.PHONY: up
up: ## Start the application
	bash -c "set -a && source ./load-env.sh $(ENV) && docker compose -f $(DC_FILE) $(DC_PROFILES) up -d" 

.PHONY: deploy
deploy: ## Deploy to environment (fetch latest tags, update env, deploy)
	@bash ./deploy.sh $(ENV) 

.PHONY: down
down: ## Stop the application
	docker compose -f $(DC_FILE) down

.PHONY: restart
restart: ## Restart the application
	$(MAKE) down ENV=$(ENV)
	$(MAKE) up ENV=$(ENV)

.PHONY: logs
logs: ## View logs
	docker compose -f $(DC_FILE) logs -f

.PHONY: ps
ps: ## Show running containers
	docker compose -f $(DC_FILE) ps

.PHONY: build
build: ## Rebuild images
	bash -c "set -a && source ./load-env.sh $(ENV) && docker compose -f $(DC_FILE) $(DC_PROFILES) build"

# =============================================================================
# Cleanup
# =============================================================================

.PHONY: clean
clean: ## Remove containers and volumes
	docker compose -f $(DC_FILE) down -v

.PHONY: prune
prune: ## Remove unused Docker resources
	powershell -ExecutionPolicy Bypass -Command "docker system prune -f"

# =============================================================================
# Help
# =============================================================================

.PHONY: help
help: ## Show this help message
	@echo "Portfolio Deployment Makefile"
	@echo "=============================="
	@echo ""
	@echo "Usage:"
	@echo "  make <target> ENV=<environment>"
	@echo ""
	@echo "Valid environments: $(VALID_ENV)"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Examples:"
	@echo "  make deploy ENV=dev         # Fetch tags, update env, deploy dev"
	@echo "  make deploy ENV=prod       # Fetch tags, update env, deploy prod"
	@echo "  make up ENV=dev          # Start dev environment"
	@echo "  make up ENV=staging     # Start staging environment"
	@echo "  make logs ENV=dev        # View dev logs"
	@echo "  make down ENV=staging     # Stop staging"
