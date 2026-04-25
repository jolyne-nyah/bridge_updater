SHELL := /bin/bash
APPS := $(shell find . -maxdepth 2 -name "go.mod" -exec dirname {} \; | sed 's|^\./||')
OUT_DIR := ../build
GO_VERSION := 1.21

.PHONY: all build clean setup update

all: update build clean

create:
	@#
	@mkdir -p $(name)
	@cd $(name) && go mod init "github.com/jolyne-nyah/bridge_updater/source/$(name)" && go mod edit -go=$(GO_VERSION)
	@echo "Module $(name) initialized with Go $(GO_VERSION)"
	@#
ifeq ($(cross),true)
	@touch $(name)/.cross
	@echo "Cross-compilation flag is set for $(name)"
endif

setup update:
	@#
	@if [ ! -f go.work ]; then go work init; fi
	@go work use $(APPS)
	@#
	@echo "Updating workspace and dependencies..."
	@for app in $(APPS); do \
		echo "  - Cleaning/Updating $$app..."; \
		(cd $$app && go mod tidy); \
	done
	@#
	@echo -e "\nWorkspace is ready. Projects found:"
	@for app in $(APPS); do echo "  - $$app"; done
	@echo

build:
	@#
	@mkdir -p $(OUT_DIR)
	@#
	@for app in $(APPS) ; do \
		echo "Building $$app..."; \
		if [ -f "./$$app/.cross" ]; then \
			echo "Found .cross in ./$$app. Cross-compiling..."; \
			CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o $(abspath $(OUT_DIR))/$$app/linux/$$app ./$$app; \
			CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o $(abspath $(OUT_DIR))/$$app/windows/$$app.exe ./$$app; \
		else \
			go build -o $(abspath $(OUT_DIR))/$$app ./$$app; \
		fi \
	done

clean:
	@#
	@echo -e "\nRemoving the Go workspace files..."
	@ rm -f go.work go.work.sum

purge:
	@#
	@echo -e "\nRemoving all built projects in $(OUT_DIR)"
	@#
	@find $(OUT_DIR) -mindepth 1 ! -name '.gitkeep' -delete