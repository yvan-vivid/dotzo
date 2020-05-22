.PHONY: check test docker-build

all: check test

test:
	@echo "Running bats tests"
	@bats tests

check: dotzo
	@echo "Checking dotzo with shellcheck"
	@shellcheck -P lib -xa $<

docker-build: Dockerfile
	docker build -f $< -t dotzo-test .
