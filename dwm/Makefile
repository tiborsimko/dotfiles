all: help

help: # Print usage help.
	@echo 'Builds and installs dwm with selected patches.'
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?# "}; {printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2}'

download: # Download dwm sources and additional patches.
	mkdir -p _src
	cd _src && \
	wget https://dl.suckless.org/dwm/dwm-6.2.tar.gz && \
	wget https://dwm.suckless.org/patches/ru_gaps/dwm-ru_gaps-6.2.diff && \
	wget https://dwm.suckless.org/patches/ru_gaps/dwm-ru_gaplessgrid-6.2.diff && \
	wget https://dwm.suckless.org/patches/ru_gaps/dwm-ru_bottomstack-6.2.diff && \
	wget https://dwm.suckless.org/patches/ru_gaps/dwm-ru_centeredmaster-6.2.diff && \
	wget https://dwm.suckless.org/patches/ru_gaps/dwm-ru_deck-6.2.diff && \
	wget https://dwm.suckless.org/patches/scratchpad/dwm-scratchpad-6.2.diff && \
	wget https://dwm.suckless.org/patches/push/dwm-push_no_master-6.2.diff && \
	wget https://dwm.suckless.org/patches/zoomswap/dwm-zoomswap-6.2.diff && \
	wget https://dwm.suckless.org/patches/focusonnetactive/dwm-focusonnetactive-2017-12-24-3756f7f.diff

build: # Build dwm executable.
	mkdir _build && cd _build && tar xvfz ../_src/dwm-6.2.tar.gz
	cd _build/dwm-6.2 && \
	patch -p1 -i ../../_src/dwm-ru_gaps-6.2.diff && \
	patch -p1 -i ../../_src/dwm-ru_gaplessgrid-6.2.diff && \
	filterdiff --lines=211,2176 ../../_src/dwm-ru_bottomstack-6.2.diff | patch -p1 && \
	patch -p1 -i ../../_src/dwm-ru_centeredmaster-6.2.diff && \
	filterdiff --lines=158,658 ../../_src/dwm-ru_deck-6.2.diff | patch -p1 && \
	patch -p1 -i ../../_src/dwm-scratchpad-6.2.diff && \
	patch -p1 -i ../../_src/dwm-push_no_master-6.2.diff && \
	patch -p1 -i ../../_src/dwm-zoomswap-6.2.diff && \
	patch -p1 -i ../../_src/dwm-focusonnetactive-2017-12-24-3756f7f.diff && \
	cp ../../config.h . && \
	make clean dwm

install: # Install dwm executable.
	cd _build && cd dwm-6.2 && make install

clean: # Remove build directory.
	rm -rf _build

deepclean: # Remove both source download and source build directories.
	rm -rf _src _build
