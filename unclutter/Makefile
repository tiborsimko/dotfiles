all: help

help: # Print usage help.
	@echo 'Builds and installs unclutter.'
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?# "}; {printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2}'

prologue: # Install prerequisite system packages
	if [ -e /etc/fedora-release ]; then sudo dnf install -y libev-devel libXfixes-devel libXi-devel asciidoc; fi

download: # Download unclutter sources.
	mkdir -p _src
	cd _src && git clone https://github.com/Airblader/unclutter-xfixes unclutter --depth=1

build: # Build unclutter executable.
	mkdir _build
	cp -r _src/unclutter _build
	cd _build/unclutter && sed -i 's,^PREFIX = /usr$$,PREFIX = /usr/local,g' Makefile && make

install: # Install unclutter executable.
	cd _build/unclutter && sudo make install

clean: # Remove build directory.
	rm -rf _build

deepclean: # Remove both source download and source build directories.
	rm -rf _src _build

