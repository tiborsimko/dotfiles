# Local Debian container for testing dotfiles.

# Build target platform; default amd64 mirrors the bare-metal Debian target.
# Expressed as ARG (not literal) to silence Docker's hardcoded-platform lint.
ARG BUILD_PLATFORM=linux/amd64

# Use Debian stable as base image, pinned to point release so updates to the
# debian:12 floating tag don't invalidate downstream build cache.
FROM --platform=$BUILD_PLATFORM debian:12

# Use default answers in installation commands
ENV DEBIAN_FRONTEND=noninteractive

# Install bootstrap packages needed before switching to the non-root user
RUN apt-get update && apt-get install -y --no-install-recommends sudo ca-certificates

# Create non-root user with passwordless sudo, matching bare-metal Debian UID
RUN useradd -u 1000 -ms /bin/bash tibor && echo 'tibor ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tibor

# Run the rest of the build as the non-root user
USER tibor
WORKDIR /home/tibor/.dotfiles

# Install apt packages from debian-packages-cli.txt
# (kept independent of install.sh so install.sh edits don't invalidate this slow layer)
COPY --chown=tibor:tibor debian-packages-cli.txt /tmp/debian-packages-cli.txt
RUN sudo apt-get update \
 && sudo apt-get install -y $(grep -vE '^[[:space:]]*(#|$)' /tmp/debian-packages-cli.txt) \
 && sudo apt-file update

# Provision the rest via install.sh, mirroring bare-metal Debian setup
COPY --chown=tibor:tibor install.sh ./install.sh
RUN ./install.sh mise
RUN ./install.sh rustup
RUN ./install.sh starship

# Drop /etc/skel-derived rc files so stow won't conflict at runtime
RUN rm -f /home/tibor/.bashrc /home/tibor/.bash_logout /home/tibor/.profile

# Generate en_GB.UTF-8 locale (done by the Debian installer on bare metal)
RUN ./install.sh locales

# Copy the full dotfiles repo and stow CLI configs at build time.
# At runtime the bind mount overlays this so relative symlinks stay valid
# and host edits propagate without rebuild.
COPY --chown=tibor:tibor . /home/tibor/.dotfiles
RUN ./stow.sh

# Set runtime default cwd to $HOME so interactive sessions feel like an ssh login
WORKDIR /home/tibor

# Tail staging area: packages being validated before folding into
# debian-packages-cli.txt. Remove each line once promoted.
RUN sudo apt-get install -y zsh
