all: help

help: # Print usage help.
	@echo 'Builds and installs st gruvbox dark and light with selected patches.'
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?# "}; {printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2}'

download: # Download st sources and additional patches.
	mkdir -p _src
	cd _src && \
	wget https://dl.suckless.org/st/st-0.8.2.tar.gz && \
	wget https://st.suckless.org/patches/fix_ime/st-ime-20190202-3be4cf1.diff && \
	wget https://st.suckless.org/patches/anysize/st-anysize-0.8.1.diff && \
	wget https://st.suckless.org/patches/externalpipe/st-externalpipe-0.8.2.diff && \
	wget https://st.suckless.org/patches/invert/st-invert-0.8.2.diff && \
	wget https://st.suckless.org/patches/keyboard_select/st-keyboard_select-0.8.2.diff && \
	wget https://st.suckless.org/patches/newterm/st-newterm-0.8.2.diff && \
	wget https://st.suckless.org/patches/scrollback/st-scrollback-0.8.2.diff && \
	wget https://st.suckless.org/patches/gruvbox/st-gruvbox-dark-0.8.2.diff && \
	wget https://st.suckless.org/patches/gruvbox/st-gruvbox-light-0.8.2.diff

build: # Build st gruvbox dark and light executables.
	mkdir _build && cd _build && tar xvfz ../_src/st-0.8.2.tar.gz
	cd _build/st-0.8.2 && \
	patch -p1 -i ../../_src/st-ime-20190202-3be4cf1.diff && \
	patch -p1 -i ../../_src/st-anysize-0.8.1.diff && \
	patch -p1 -i ../../_src/st-externalpipe-0.8.2.diff && \
	patch -p1 -i ../../_src/st-invert-0.8.2.diff && \
	patch -p1 -F4 -i ../../_src/st-keyboard_select-0.8.2.diff && \
	patch -p1 -F4 -i ../../_src/st-newterm-0.8.2.diff && \
	patch -p1 -F4 -i ../../_src/st-scrollback-0.8.2.diff && \
	patch -p1 -i ../../_src/st-gruvbox-dark-0.8.2.diff && \
	cp ../../config.h . && \
	patch -p1 -i ../../config.h.gruvbox-dark-to-gruvbox-light.diff && make clean st && mv st st-gruvbox-light && \
	cp ../../config.h . && \
	make clean st && cp -a st st-gruvbox-dark


install: # Install st gruvbox dark and light executables.
	cd _build && cd st-0.8.2 && make install
	cd _build && cd st-0.8.2 && cp -a st-gruvbox-dark /usr/local/bin
	cd _build && cd st-0.8.2 && cp -a st-gruvbox-light /usr/local/bin

clean: # Remove build directory.
	rm -rf _build

deepclean: # Remove both source download and source build directories.
	rm -rf _src _build
