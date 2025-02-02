# kodak makefile

PROJECT = kodak
VERSION = $(shell poetry version --short)

.PHONY: help
# Put it first so that "make" without argument is like "make help"
# Adapted from:
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## List Makefile targets
	$(info Makefile documentation)
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

clean-tox:
	rm --recursive --force ./.mypy_cache
	rm --recursive --force ./.tox
	rm --force .coverage
	rm --force ./$(PROJECT)/openapi.yaml
	find ./tests -type d -name __pycache__ -prune -exec rm --recursive --force {} \;

clean-py:
	rm --recursive --force ./dist
	rm --recursive --force ./build
	rm --recursive --force ./*.egg-info
	find ./$(PROJECT) -type d -name __pycache__ -prune -exec rm --recursive --force {} \;

clean: clean-tox clean-py ## Clean temp build/cache files and directories
	rm --force ./*db*

prep:
	cp ./openapi.yaml ./$(PROJECT)/openapi.yaml

wheel: prep ## Build Python binary distribution wheel package
	poetry build --format wheel

source: prep ## Build Python source distribution package
	poetry build --format sdist

image: prep
	docker build . --tag $(PROJECT):$(VERSION)
	docker image save $(PROJECT):$(VERSION) --output dist/$(PROJECT)-$(VERSION)-docker.tar.gz

build: clean wheel source image; ## Build all distribution packages

test: clean-tox prep ## Run the project testsuite(s)
	poetry run tox

publish: clean test build ## Build and upload to pypi (requires $PYPI_API_KEY be set)
	@poetry publish --username __token__ --password $(PYPI_API_KEY)

dev: ## Create local dev environment
	poetry install --remove-untracked
	poetry run pre-commit install
