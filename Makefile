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

docker-test: # Run smoke tests in the Docker container (batch mode).
	@docker run --rm \
	  --platform linux/amd64 \
	  --hostname dotfiles-test \
	  -v $(PWD):/home/tibor/.dotfiles \
	  $(IMAGE) \
	  bash -c 'err=$$(bash -lic true 2>&1 1>/dev/null | grep -vE "cannot set terminal process group|no job control in this shell"); [ -z "$$err" ] && echo OK || { echo "FAIL: $$err"; exit 1; }; bash -lic "set -e; nvim --version | head -1; starship --version; helm version --short; kubectl version --client 2>/dev/null | head -1; kind version; hx --version | head -1; delta --version; lazygit --version | head -1; cr version | head -1; for v in 3.13 3.12 3.10 3.9 3.8; do python\$$v --version; done"'
