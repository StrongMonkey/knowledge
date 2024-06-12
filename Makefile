# get git tag
ifneq ($(GIT_TAG_OVERRIDE),)
$(info GIT_TAG set from env override!)
GIT_TAG := $(GIT_TAG_OVERRIDE)
endif

GIT_TAG   ?= $(shell git describe --tags)
ifeq ($(GIT_TAG),)
GIT_TAG   := $(shell git describe --always)
endif

GO_TAGS := netgo
LD_FLAGS := -s -w -X github.com/gptscript-ai/knowledge/version.Version=${GIT_TAG}
build:
	go build -o bin/knowledge -tags "${GO_TAGS}" -ldflags '$(LD_FLAGS) ' .

run: build
	bin/knowledge server

run-dev: generate run

clean-dev:
	rm -rf knowledge.db vector.db

generate: tools openapi

openapi:
	swag init --parseDependency -g pkg/server/server.go -o pkg/docs

tools:
	if ! command -v swag &> /dev/null; then go install github.com/swaggo/swag/cmd/swag@latest; fi

lint:
	golangci-lint run ./...

test:
	go test -v ./...

build-cross:
	if [ "$(GOOS)" = "linux" ]; then \
		CGO_ENABLED=1 GOARCH=arm64 go build -o dist/knowledge-darwin-arm64 -tags "${GO_TAGS}" -ldflags '$(LD_FLAGS) -extldflags "-static"' . \
	else \
		# window amd64
		CGO_ENABLED=1 CC=x86_64-w64-mingw32-gcc GOOS=windows GOARCH=amd64 go build -o dist/knowledge-windows-amd64 -tags "${GO_TAGS}" -ldflags '$(LD_FLAGS)' . \
		# darwin amd64
		CGO_ENABLED=1 GOARCH=amd64 go build -o dist/knowledge-darwin-amd64 -tags "${GO_TAGS}" -ldflags '$(LD_FLAGS)' . \
		#darwin arm64
		CGO_ENABLED=1 GOARCH=arm64 go build -o dist/knowledge-darwin-arm64 -tags "${GO_TAGS}" -ldflags '$(LD_FLAGS)' . \
	fi

gen-checksum:	build-cross
	$(eval ARTIFACTS_TO_PUBLISH := $(shell ls dist/*))
	$$(sha256sum $(ARTIFACTS_TO_PUBLISH) > dist/checksums.txt)

ci-setup:
	@echo "### Installing Go tools..."
	@echo "### -> Installing golangci-lint..."
	curl -sfL $(PKG_GOLANGCI_LINT_SCRIPT) | sh -s -- -b $(GOENVPATH)/bin v$(PKG_GOLANGCI_LINT_VERSION)

