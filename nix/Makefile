all: help

help: # Print usage help.
	@echo 'Installs Nix.'
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?# "}; {printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2}'

download: # Download Nix sources.
	mkdir -p _src
	cd _src && curl -o install-nix-2.3.8 https://releases.nixos.org/nix/nix-2.3.8/install
	cd _src && curl -o install-nix-2.3.8.asc https://releases.nixos.org/nix/nix-2.3.8/install.asc
	cd _src && gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys B541D55301270E0BCF15CA5D8170B4726D7198DE
	cd _src && gpg2 --verify ./install-nix-2.3.8.asc

install: # Install Nix
	cd _src && sh ./install-nix-2.3.8

epilogue: # Install selected Nix packages
	cd .. && stow --no-folding nix
	nix-env -i autocutsel
	nix-env -i clipmenu
	nix-env -i discord
	nix-env -i fasd-unstable
	nix-env -i helm
	nix-env -i kind
	nix-env -i mons
	nix-env -i scrot

clean: # Remove build directory.
	rm -rf _src/install-nix-2.3.8 _src/install-nix-2.3.8.asc

deepclean: # Remove both source download and source build directories.
	rm -rf _src
