.PHONY: run test migrate-up migrate-down migrate-create migrate-force migrate-version lint fmt help

# Load environment variables from .env
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

## run: Run the application
run:
	go run cmd/api/main.go

## test: Run tests
test:
	go test -v ./...

## test-cover: Run tests with coverage
test-cover:
	go test -v -cover ./...

## migrate-up: Run all up migrations
migrate-up:
	migrate -path migrations -database "$(DATABASE_URL)" up

## migrate-down: Rollback last migration
migrate-down:
	migrate -path migrations -database "$(DATABASE_URL)" down 1

## migrate-down-all: Rollback all migrations
migrate-down-all:
	migrate -path migrations -database "$(DATABASE_URL)" down

## migrate-create: Create a new migration (usage: make migrate-create name=migration_name)
migrate-create:
	migrate create -ext sql -dir migrations -seq $(name)

## migrate-force: Force migration version (usage: make migrate-force version=X)
migrate-force:
	migrate -path migrations -database "$(DATABASE_URL)" force $(version)

## migrate-version: Show current migration version
migrate-version:
	migrate -path migrations -database "$(DATABASE_URL)" version

## lint: Run golangci-lint
lint:
	golangci-lint run

## fmt: Format code
fmt:
	go fmt ./...

## tidy: Tidy go.mod
tidy:
	go mod tidy

## help: Show this help message
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'