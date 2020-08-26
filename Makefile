PACKAGE ?= gofer
GO_FILES := $(shell { git ls-files; } | grep ".go$$")
LICENSED_FILES := $(shell { git ls-files; } | grep ".go$$")

BUILD_SOURCE := cmd/gofer/main.go
BUILD_DIR := bin
BUILD_TARGET := $(BUILD_DIR)/gofer
BUILD_FLAGS ?= all

OUT_DIR := workdir
COVER_FILE := $(OUT_DIR)/cover.out
TEST_FLAGS ?= all

GO := go

all: $(BUILD_TARGET)
.PHONY: all

$(BUILD_TARGET): export GOOS ?= linux
$(BUILD_TARGET): export GOARCH ?= amd64
$(BUILD_TARGET): export CGO_ENABLED ?= 0
$(BUILD_TARGET): $(BUILD_SOURCE) $(GO_FILES)
	mkdir -p $(@D)
	$(GO) build -tags $(BUILD_FLAGS) -o $@ $<

clean:
	rm -rf $(OUT_DIR) $(BUILD_DIR)
.PHONY: clean

lint:
	golangci-lint run ./...
.PHONY: lint

test:
	$(GO) test -tags $(TEST_FLAGS) ./...
.PHONY: test

test-license: $(LICENSED_FILES)
	@grep -vlz "$$(tr '\n' . < LICENSE_HEADER)" $^ && exit 1 || exit 0
.PHONY: test-license

test-all: lint test test-license
.PHONY: test-all

cover:
	@mkdir -p $(dir $(COVER_FILE))
	$(GO) test -tags $(TEST_FLAGS) -coverprofile=$(COVER_FILE) ./...
	$(GO) tool cover -func=$(COVER_FILE)
.PHONY: cover

bench:
	$(GO) test -tags $(TEST_FLAGS) -bench=. ./...
.PHONY: bench

add-license: $(LICENSED_FILES)
	for x in $^; do tmp=$$(cat LICENSE_HEADER; sed -n '/^package \|^\/\/ *+build /,$$p' $$x); echo "$$tmp" > $$x; done
.PHONY: add-license

