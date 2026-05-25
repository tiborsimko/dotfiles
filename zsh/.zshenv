# Tibor's zshenv configuration.

# This file is sourced by all zsh instances (including non-interactive). This
# file sets only those environment variables that are of interest for
# non-interactive tools (LSP servers etc).

# Set custom Go path
export GOPATH=$HOME/private/go

# Locale (needed by tools that process text, e.g. sort, grep)
export LANG="en_GB.UTF-8"
export LC_ALL="en_GB.UTF-8"
