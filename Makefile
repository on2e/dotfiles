SHELL = /usr/bin/env bash
.SHELLFLAGS = -o errexit -o nounset -o pipefail -c

.PHONY: all
all: install

##@ General

.PHONY: help
help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Dotfiles

# Additional ansible-playbook options, e.g. make ARGS='--tags mytag'
ARGS ?=

.PHONY: install
install: ## Set up host using Ansible
	@cd .ansible; \
	$(UV) run ansible-playbook --ask-become-pass playbook.yaml $(ARGS)

.PHONY: packages
packages: override ARGS += --tags packages
packages: install ## Run only the 'packages' Ansible role

.PHONY: dotfiles
dotfiles: override ARGS += --tags dotfiles
dotfiles: install ## Run only the 'dotfiles' Ansible role

.PHONY: tools
tools: override ARGS += --tags tools
tools: install ## Run only the 'tools' Ansible role

##@ Dependencies

LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

UV ?= $(LOCALBIN)/uv

.PHONY: setup
setup: uv ## Create virtual environment and install dependencies with uv
	@$(UV) venv
	@$(UV) pip install -r requirements.txt

.PHONY: uv
uv: $(UV) ## Install latest uv locally with installer script using curl
$(UV): | $(LOCALBIN)
	@curl -sSfL 'https://astral.sh/uv/install.sh' | \
	UV_INSTALL_DIR='$(LOCALBIN)' UV_NO_MODIFY_PATH='1' bash

##@ Clean

.PHONY: clean
clean: ## Remove virtual environment and local binaries directories
	rm -rf .venv
	rm -rf $(LOCALBIN)
