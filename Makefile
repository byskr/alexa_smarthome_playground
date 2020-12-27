LIST_ALL := $(shell go list ./... | grep -v vendor | grep -v mocks)

# Force using Go Modules and always read the dependencies from
# the `vendor` folder.
export GOFLAGS = -mod=vendor

all: lint test package

.PHONY: install
install: ## Install the dependencies
	@go mod vendor

.PHONY: update
update: ## Update the dependencies
	@go mod tidy

.PHONY: upgrade
upgrade: ## Upgrade the dependencies
	@go get -u -t ./...
	@go mod tidy
	@go mod vendor

.PHONY: clean
clean: ## Remove binaries and ZIP files based on directory `./cmd/`
	@rm -rf "$(go env GOCACHE)"
	@rm -rf bin/
	@rm -f coverage.*

.PHONY: lint
lint: ## Lint all files (via golangci-lint)
	@go fmt ${LIST_ALL}
	@golangci-lint version
	@golangci-lint run

.PHONY: test
test: clean ## Run unit tests (no race)
	@go test -short -timeout=180s ${LIST_ALL}

.PHONY: coverage
coverage: test ## Generate coverage report
	@go-acc ${LIST_ALL} -- -v
	@go tool cover -func coverage.txt

.PHONY: report
report: coverage ## Open the coverage report in browser
	@go tool cover -html=coverage.txt

.PHONY: build
build: clean ## Build all binaries based on directory `./cmd/`
	@for CMD in `ls cmd`; do GOOS=linux GOARCH=amd64 go build -o ./bin/$$CMD ./cmd/$$CMD; done

.PHONY: package
package: build ## Generate ZIP files of binaries based on directory `./cmd/`
	@for CMD in `ls cmd`; do chmod +x ./bin/$$CMD && zip -j ./bin/$$CMD.zip ./bin/$$CMD ; done

# ----------------------------------------------------------------------------------------------------------------------

help: ## Display this help screen
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
