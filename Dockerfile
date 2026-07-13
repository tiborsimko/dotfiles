# Local Debian container for testing dotfiles.

# Build target platform; default amd64 mirrors the bare-metal Debian target.
# Expressed as ARG (not literal) to silence Docker's hardcoded-platform lint.
ARG BUILD_PLATFORM=linux/amd64

# Use Debian stable as base image, pinned to a major version so floating
# `latest`/`stable` tag updates don't invalidate downstream build cache.
# `debian:13` itself still tracks the latest 13.x point release.
FROM --platform=$BUILD_PLATFORM debian:13

# Install bootstrap packages needed before switching to the non-root user
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends sudo ca-certificates

# Create non-root user with passwordless sudo, matching bare-metal Debian UID
RUN useradd -u 1000 -ms /bin/bash tibor && echo 'tibor ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tibor

# Run the rest of the build as the non-root user. Mirror the documented host
# checkout depth so tests do not rely on the repository being directly in $HOME.
USER tibor
WORKDIR /home/tibor/Code/github.com/tiborsimko/dotfiles

# Install apt packages from debian-packages-cli.txt
# (kept independent of install.sh so install.sh edits don't invalidate this slow layer)
COPY --chown=tibor:tibor debian-packages-cli.txt /tmp/debian-packages-cli.txt
RUN sudo apt-get update \
  && sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y $(grep -vE '^[[:space:]]*(#|$)' /tmp/debian-packages-cli.txt) \
  && sudo apt-file update

# Provision the rest via install.sh, mirroring bare-metal Debian setup
COPY --chown=tibor:tibor install.sh ./install.sh
RUN DEBIAN_FRONTEND=noninteractive ./install.sh mise

# Pre-stage mise config so the mise-install layer is keyed on config.toml,
# not on every dotfile edit. The stow step further down replaces it with a symlink.
RUN mkdir -p /home/tibor/.config/mise
COPY --chown=tibor:tibor mise/linux/.config/mise/config.toml /home/tibor/.config/mise/config.toml
RUN ./install.sh mise-tools

# Drop /etc/skel-derived rc files so stow won't conflict at runtime
RUN rm -f /home/tibor/.bashrc /home/tibor/.bash_logout /home/tibor/.profile

# Generate en_GB.UTF-8 locale (done by the Debian installer on bare metal)
RUN DEBIAN_FRONTEND=noninteractive ./install.sh locales

# Copy the full dotfiles repo and stow CLI configs at build time.
# At runtime the bind mount overlays this so relative symlinks stay valid
# and host edits propagate without rebuild.
COPY --chown=tibor:tibor . .
# Drop the pre-staged mise config so stow can place a symlink in its stead.
RUN rm -f /home/tibor/.config/mise/config.toml && ./stow.sh all

# Set runtime default cwd to $HOME so interactive sessions feel like an ssh login
WORKDIR /home/tibor
