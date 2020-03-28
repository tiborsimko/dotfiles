all: help

help: # Print usage help.
	@echo 'Builds and installs slstatus.'
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?# "}; {printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2}'

download: # Download slstatus sources.
	mkdir -p _src
	cd _src && git clone git://git.suckless.org/slstatus --depth=1

build: # Build slstatus executable.
	mkdir _build
	cp -r _src/slstatus _build
	cd _build/slstatus && cp ../../config.h . && make clean slstatus

install: # Install slstatus executable.
	cd _build/slstatus && make install

clean: # Remove build directory.
	rm -rf _build

deepclean: # Remove both source download and source build directories.
	rm -rf _src _build

