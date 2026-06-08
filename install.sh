#!/usr/bin/env bash

# Installation script for Debian. Installs base system packages and custom
# local software. Dotfile linking is handled separately by `stow.sh`.
# See `--help` for usage.

# Define desired versions of custom software
NERDFONTS=v3.3.0

set -o errexit
set -o nounset

# Wrap apt install so the caller's `DEBIAN_FRONTEND` propagates through
# `sudo`, which resets env by default. Bare-metal callers stay interactive;
# set `DEBIAN_FRONTEND=noninteractive` in the calling context (e.g. a
# `Dockerfile` `RUN`) to silence debconf. `apt-get` is the scripting-stable
# interface.
apt_install() {
  # shellcheck disable=SC2086  # intentional: empty expansion if VAR is unset
  sudo env ${DEBIAN_FRONTEND:+DEBIAN_FRONTEND="$DEBIAN_FRONTEND"} \
    apt-get install -y "$@"
}

install_base_cli() {
  # shellcheck disable=SC2046
  apt_install $(grep -vE '^[[:space:]]*(#|$)' debian-packages-cli.txt)
  sudo apt-file update
}

install_base_gui() {
  # Enable contrib and non-free components first so firmware packages from
  # non-free-firmware (e.g. firmware-iwlwifi) are resolvable below.
  # apt-add-repository takes one positional argument, so loop with -c.
  for component in contrib non-free non-free-firmware; do
    sudo apt-add-repository -y -c "$component"
  done
  # shellcheck disable=SC2046
  apt_install $(grep -vE '^[[:space:]]*(#|$)' debian-packages-gui.txt)
  # Prefer text console login
  sudo systemctl set-default multi-user.target
  # Prefer Firefox ESR browser
  BROWSER="" xdg-settings set default-web-browser firefox-esr.desktop
}

install_latex() {
  apt_install \
    latexmk \
    texlive-extra-utils \
    texlive-latex-extra
}

install_locales() {
  apt_install locales
  sudo sed -i 's/^# *en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
  sudo locale-gen
}

install_mise() {
  sudo install -dm 755 /etc/apt/keyrings
  curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.asc 1>/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
  sudo apt update -y
  apt_install mise
}

install_mise_tools() {
  mise trust ~/.config/mise/config.toml
  mise install
  mise exec -- helm plugin list 2>/dev/null | grep -q '^diff' \
    || mise exec -- helm plugin install --verify=false https://github.com/databus23/helm-diff
}

install_nerdfonts() {
  cd ~/Downloads
  rm -f LiberationMono.zip
  wget https://github.com/ryanoasis/nerd-fonts/releases/download/${NERDFONTS}/LiberationMono.zip
  mkdir -p ~/.local/share/fonts
  cd ~/.local/share/fonts
  unzip -o ~/Downloads/LiberationMono.zip
  rm -f ~/Downloads/LiberationMono.zip
  fc-cache
}

install_mons() {
  if [ -d ~/Downloads/mons ]; then
    cd ~/Downloads/mons
    git fetch origin
    git reset --hard origin/master
  else
    git clone --recursive https://github.com/Ventto/mons ~/Downloads/mons
  fi
  cd ~/Downloads/mons
  sed -i -e 's,^PREFIX      = /usr$$,PREFIX      = /usr/local,g' Makefile
  sudo make install
}

install_docker() {
  for pkg in \
    docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get -y remove $pkg; done
  sudo apt-get update -y
  apt_install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  # shellcheck source=/dev/null
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -y
  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo adduser "${USER}" docker
}

install_gtktheme() {
  if [ ! -d ~/.themes/gruvbox-dark-gtk ]; then
    git clone https://github.com/jmattheis/gruvbox-dark-gtk ~/.themes/gruvbox-dark-gtk
  fi
  if [ ! -d ~/.icons/gruvbox-dark-icons-gtk ]; then
    git clone https://github.com/jmattheis/gruvbox-dark-icons-gtk ~/.icons/gruvbox-dark-icons-gtk
  fi
}

install_thinkfan() {
  local conf
  conf="thinkfan/$(hostname)/thinkfan.conf"
  if [ ! -f "$conf" ]; then
    echo "[ERROR] No thinkfan config for $(hostname) (expected $conf)."
    exit 1
  fi
  apt_install thinkfan
  if [ ! -f /etc/modprobe.d/thinkpad_acpi.conf ]; then
    echo "options thinkpad_acpi fan_control=1" | sudo tee /etc/modprobe.d/thinkpad_acpi.conf
  fi
  sudo modprobe -rv thinkpad_acpi
  sudo modprobe -v thinkpad_acpi
  sudo cp -a "$conf" /etc/
  sudo systemctl enable --now thinkfan.service
  sudo systemctl restart thinkfan.service
}

install_tlp() {
  local conf
  conf="tlp/$(hostname)/tlp.conf"
  if [ ! -f "$conf" ]; then
    echo "[ERROR] No tlp config for $(hostname) (expected $conf)."
    exit 1
  fi
  apt_install tlp
  sudo cp -a "$conf" /etc/
  sudo systemctl enable --now tlp.service
  sudo systemctl restart tlp.service
}

install_ufw() {
  apt_install ufw
  sudo systemctl enable --now ufw.service
  sudo ufw enable
  sudo ufw status verbose
}

configure_firefox() {
  echo "Install the following extensions:"
  echo
  echo "- Bitwarden Password Manager"
  echo "- Firefox Multi-Account Containers"
  echo "- Simple Tab Groups"
  echo "- uBlock Origin"
  echo "- Vimium"
  echo
  echo "Configure Vimium:"
  echo
  echo "- Don't let pages steal the focus on load = yes"
  echo
  echo "Copy customisations into your profile directory, for example:"
  echo
  echo "- mkdir ~/.mozilla/firefox/*.default-esr/chrome"
  echo "- cp firefox/.mozilla/firefox/user.js ~/.mozilla/firefox/*.default-esr/"
  echo "- cp firefox/.mozilla/firefox/chrome/userChrome.css ~/.mozilla/firefox/*.default-esr/chrome/"
}

install_oc() {
  curl -L https://downloads-openshift-console.paas.cern.ch/amd64/linux/oc.tar | sudo tar xv -C /usr/local/bin
  sudo chmod a+rx /usr/local/bin/oc
  curl -sL https://gitlab.cern.ch/paas-tools/oc-sso-login/-/raw/master/oc-sso-login.py | sudo tee -a /usr/local/bin/oc-sso_login
  sudo chmod a+xr /usr/local/bin/oc-sso_login
}

install_brave() {
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
  sudo apt update -y
  apt_install brave-browser
  # Prefer Brave browser
  BROWSER="" xdg-settings set default-web-browser brave-browser.desktop
}

install_librewolf() {
  apt_install extrepo
  sudo extrepo enable librewolf
  sudo apt update -y && apt_install librewolf
  # Prefer LibreWolf browser
  BROWSER="" xdg-settings set default-web-browser brave-browser.desktop
}

install_floorp() {
  curl -fsSL https://ppa.floorp.app/KEY.gpg | sudo gpg --dearmor -o /usr/share/keyrings/Floorp.gpg
  sudo curl -sS --compressed -o /etc/apt/sources.list.d/Floorp.list "https://ppa.floorp.app/Floorp.list"
  sudo apt update
  apt_install floorp
  # Prefer Floorp browser
  BROWSER="" xdg-settings set default-web-browser floorp.desktop
}

help() {
  echo "Usage: $0 [options] <target>"
  echo "Options:"
  echo "  --help        Show this help [default]"
  echo "Targets (in recommended order):"
  echo "  base-cli      Install CLI base packages"
  echo "  base-gui      Install GUI base packages"
  echo "  mise          Install mise"
  echo "  mise-tools    Install all tools declared in ~/.config/mise/config.toml"
  echo "  gtktheme      Install GTK theme"
  echo "  mons          Install mons"
  echo "  nerdfonts     Install nerdfonts"
  echo "Targets (apps):"
  echo "  docker        Install docker"
  echo "  latex         Install LaTeX (texlive)"
  echo "  locales       Install and generate en_GB.UTF-8 locale"
  echo "Targets (optional):"
  echo "  brave         Install brave"
  echo "  firefox       Configure firefox"
  echo "  floorp        Install floorp"
  echo "  librewolf     Install librewolf"
  echo "  oc            Install oc"
  echo "  thinkfan      Install thinkfan"
  echo "  tlp           Install tlp"
  echo "  ufw           Install ufw"
}

mkdir -p ~/Local/mbsyncmail

if [ $# -eq 0 ]; then
  help
  exit 0
fi

arg="$1"
case $arg in
--help) help ;;
base-cli) install_base_cli ;;
base-gui) install_base_gui ;;
brave) install_brave ;;
docker) install_docker ;;
firefox) configure_firefox ;;
floorp) install_floorp ;;
gtktheme) install_gtktheme ;;
latex) install_latex ;;
librewolf) install_librewolf ;;
locales) install_locales ;;
mise) install_mise ;;
mise-tools) install_mise_tools ;;
mons) install_mons ;;
nerdfonts) install_nerdfonts ;;
oc) install_oc ;;
thinkfan) install_thinkfan ;;
tlp) install_tlp ;;
ufw) install_ufw ;;
*) echo "[ERROR] Invalid argument '$arg'. Exiting." && help && exit 1 ;;
esac
