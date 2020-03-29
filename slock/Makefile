all: help

help: # Print usage help.
	@echo 'Builds and installs slock.'
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?# "}; {printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2}'

download: # Download slock sources and additional patches.
	mkdir -p _src
	cd _src && \
	wget https://dl.suckless.org/tools/slock-1.4.tar.gz

build: # Build slock executable.
	mkdir _build && cd _build && tar xvfz ../_src/slock-1.4.tar.gz
	cd _build/slock-1.4 && \
	cp ../../config.h . && \
	make clean slock

install: # Install slock executable.
	cd _build && cd slock-1.4 && sudo make install

clean: # Remove build directory.
	rm -rf _build

deepclean: # Remove both source download and source build directories.
	rm -rf _src _build
