# Targets for building and running the local Debian test container.

IMAGE := docker.io/tiborsimko/dotfiles-debian:12

.PHONY: help docker-build docker-run docker-test

help: # Print usage help information.
	@echo "Available commands:"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?# "}; {printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2}'

docker-build: # Build Docker image for testing dotfiles on Debian.
	docker build --load --provenance=false -t $(IMAGE) .

docker-run: # Open an interactive shell in the Docker container.
	docker run --rm -it \
	  --platform linux/amd64 \
	  --hostname dotfiles-test \
	  -v $(PWD):/home/tibor/.dotfiles \
	  $(IMAGE) \
	  bash -l

docker-test: # Run dotfiles tests inside the Docker container.
	@docker run --rm -t \
	  --platform linux/amd64 \
	  --hostname dotfiles-test \
	  -v $(PWD):/home/tibor/.dotfiles \
	  $(IMAGE) \
	  /home/tibor/.dotfiles/test.sh
