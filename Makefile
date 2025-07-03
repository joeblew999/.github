# Makefile for GitHub Organization Setup
# This is a simple alternative to Taskfile.yml for users who prefer Make

.PHONY: help setup clean check status dev install-gh verify-github validate-all
.DEFAULT_GOAL := help

GITHUB_ORG := joeblew999

help: ## Show this help message
	@echo "GitHub Organization Setup Tool"
	@echo "=============================="
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Quick start: make setup"
	@echo "For full features, consider using Task instead: task --list"

setup: clean ## Generate all .github files from templates
	@mkdir -p .github profile
	@go run cmd/github-setup/main.go -org=$(GITHUB_ORG)

clean: ## Remove generated .github files
	@rm -rf .github/ISSUE_TEMPLATE .github/issue-templates .github/workflows .github/CODEOWNERS .github/dependabot.yml .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE

check: ## Check if generated files are up to date
	@echo "Checking if generated files are up to date..."
	@TEMP_DIR=$$(mktemp -d) && \
	go run cmd/github-setup/main.go -org=$(GITHUB_ORG) -output="$$TEMP_DIR" && \
	if ! diff -r .github "$$TEMP_DIR" > /dev/null 2>&1; then \
		echo "❌ Generated files are out of date. Run 'make setup' to update." && \
		rm -rf "$$TEMP_DIR" && \
		exit 1; \
	else \
		echo "✅ Generated files are up to date." && \
		rm -rf "$$TEMP_DIR"; \
	fi

status: ## Show current system status
	@echo "🏢 GitHub Organization: $(GITHUB_ORG)"
	@echo "📁 Repository: https://github.com/$(GITHUB_ORG)/.github"
	@echo ""
	@echo "📊 System Status:"
	@if [ -d ".github" ]; then echo "✅ Generated files exist"; else echo "❌ Generated files missing - run 'make setup'"; fi
	@if go mod verify >/dev/null 2>&1; then echo "✅ Go module verified"; else echo "❌ Go module issues - run 'go mod tidy'"; fi
	@if command -v gh >/dev/null 2>&1; then echo "✅ GitHub CLI available"; else echo "❌ GitHub CLI not installed"; fi

dev: clean setup check ## Development workflow
	@echo "✅ Development workflow complete"

install-gh: ## Install GitHub CLI (requires Task)
	@echo "GitHub CLI installation requires Task. Run: task install-gh"

verify-github: ## Verify GitHub state (requires Task)  
	@echo "GitHub verification requires Task. Run: task verify-github"

validate-all: ## Run all validations (requires Task)
	@echo "Full validation requires Task. Run: task validate-all"
