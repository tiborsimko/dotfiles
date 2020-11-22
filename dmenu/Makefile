all: help

help: # Print usage help.
	@echo 'Builds and installs dmenu with selected patches.'
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?# "}; {printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2}'

download: # Download dmenu sources and additional patches.
	mkdir -p _src
	cd _src && \
	wget https://dl.suckless.org/tools/dmenu-5.0.tar.gz && \
	wget https://tools.suckless.org/dmenu/patches/fuzzymatch/dmenu-fuzzymatch-4.9.diff && \
	wget https://tools.suckless.org/dmenu/patches/fuzzyhighlight/dmenu-fuzzyhighlight-4.9.diff

build: # Build dmenu executable.
	mkdir _build && cd _build && tar xvfz ../_src/dmenu-5.0.tar.gz
	cd _build/dmenu-5.0 && \
	patch -p1 -i ../../_src/dmenu-fuzzymatch-4.9.diff && \
	patch -p1 -i ../../_src/dmenu-fuzzyhighlight-4.9.diff && \
	cp ../../config.h . && \
	make clean dmenu

install: # Install dmenu executable.
	cd _build && cd dmenu-5.0 && sudo make install

clean: # Remove build directory.
	rm -rf _build

deepclean: # Remove both source download and source build directories.
	rm -rf _src _build
