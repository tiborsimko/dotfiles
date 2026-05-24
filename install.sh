#!/usr/bin/env bash

# Installation script for Debian. Installs base system packages and custom
# local software. Dotfile linking is handled separately by `stow.sh`.
# See `--help` for usage.

# Define desired versions of custom software
ALACRITTY=v0.15.1
CR=v1.7.0
DELTA=0.18.2
HELIX=25.01.1
HELM=v3.17.2
KIND=v0.27.0
KUBECTL=v1.32.3
LAZYGIT=v0.48.0
NERDFONTS=v3.3.0
NVIM=v0.10.4
PY310=3.10.16
PY312=3.12.9
PY313=3.13.2
PY38=3.8.20
PY39=3.9.21
STARSHIP=v1.22.1

set -o errexit
set -o nounset

install_base_cli() {
  # shellcheck disable=SC2046
  sudo apt install -y $(grep -vE '^[[:space:]]*(#|$)' debian-packages-cli.txt)
  sudo apt-file update
}

install_base_gui() {
  # shellcheck disable=SC2046
  sudo apt install -y $(grep -vE '^[[:space:]]*(#|$)' debian-packages-gui.txt)
  # Add non-free repositories
  sudo apt-add-repository -y contrib non-free non-free-firmware
  # Prefer text console login
  sudo systemctl set-default multi-user.target
  # Prefer Firefox ESR browser
  BROWSER="" xdg-settings set default-web-browser firefox-esr.desktop
}

install_latex() {
  sudo apt install -y \
    latexmk \
    texlive-extra-utils \
    texlive-latex-extra
}

install_locales() {
  sudo apt install -y locales
  sudo sed -i 's/^# *en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
  sudo locale-gen
}

install_mise() {
  sudo install -dm 755 /etc/apt/keyrings
  curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.asc 1>/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
  sudo apt update -y
  sudo apt install -y mise
}

install_backports() {
  # Add backports repository
  if [ ! -f /etc/apt/sources.list.d/bookworm-backports.list ]; then
    echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/bookworm-backports.list
    sudo apt update -y
  fi
  # Install some packages from backports
  sudo apt install -y -t bookworm-backports \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-iwlwifi \
    golang \
    linux-headers-amd64 \
    linux-image-amd64
  # Work around for backports missing iwlwifi firmware bug <https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1092342>
  cd ~/Downloads
  if [ ! -f ~/Downloads/firmware-iwlwifi_20241210-1_all.deb ]; then
    curl -O http://ftp.fr.debian.org/debian/pool/non-free-firmware/f/firmware-nonfree/firmware-iwlwifi_20241210-1_all.deb
  fi
  sudo dpkg -i ./firmware-iwlwifi_20241210-1_all.deb
}

install_nvim() {
  sudo apt -y build-dep neovim
  if [ -d ~/Downloads/neovim ]; then
    cd ~/Downloads/neovim
    git fetch origin
    git reset --hard origin/master
  else
    git clone https://github.com/neovim/neovim ~/Downloads/neovim
  fi
  cd ~/Downloads/neovim
  git reset --hard ${NVIM}
  git clean -d -ff -x
  make CMAKE_BUILD_TYPE=RelWithDebInfo
  cd build && cpack -G DEB
  sudo dpkg -i nvim-linux-x86_64.deb
}

clean_nvim() {
  rm -rf ~/.cache/nvim
  rm -rf ~/.config/nvim
  rm -rf ~/.local/share/nvim
  rm -rf ~/.local/state/nvim
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

install_rustup() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  . "$HOME/.cargo/env"
  rustup override set stable
  rustup update stable
  cargo install cargo-deb
}

install_alacritty() {
  sudo apt -y install cmake g++ pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
  if [ -d ~/Downloads/alacritty ]; then
    cd ~/Downloads/alacritty
    git fetch origin
    git reset --hard origin/master
  else
    git clone https://github.com/alacritty/alacritty ~/Downloads/alacritty
  fi
  cd ~/Downloads/alacritty
  git reset --hard ${ALACRITTY}
  git clean -d -ff -x
  cargo build --release
  sudo install ./target/release/alacritty /usr/local/bin
}

install_delta() {
  if [ -d ~/Downloads/delta ]; then
    cd ~/Downloads/delta
    git fetch origin
    git reset --hard origin/main
  else
    git clone https://github.com/dandavison/delta ~/Downloads/delta
  fi
  cd ~/Downloads/delta
  git reset --hard ${DELTA}
  git clean -d -ff -x
  cargo build --release
  sudo install ./target/release/delta /usr/local/bin
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
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  # shellcheck source=/dev/null
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
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

install_starship() {
  [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
  if [ -d ~/Downloads/starship ]; then
    cd ~/Downloads/starship
    git fetch origin
    git reset --hard origin/master
  else
    git clone https://github.com/starship/starship ~/Downloads/starship
  fi
  cd ~/Downloads/starship
  git reset --hard ${STARSHIP}
  git clean -d -ff -x
  cargo build --release
  sudo install ./target/release/starship /usr/local/bin
}

install_helix() {
  if [ -d ~/Downloads/helix ]; then
    cd ~/Downloads/helix
    git fetch origin
    git reset --hard origin/master
  else
    git clone https://github.com/helix-editor/helix ~/Downloads/helix
  fi
  cd ~/Downloads/helix
  git reset --hard ${HELIX}
  git clean -d -ff -x
  cargo-deb -- --locked
  sudo dpkg -i ./target/debian/helix_25.1.1-1_amd64.deb
}

install_helm() {
  cd ~/Downloads
  rm -f helm-${HELM}-linux-amd64.tar.gz
  rm -f helm-${HELM}-linux-amd64.tar.gz.sha256sum
  curl -O https://get.helm.sh/helm-${HELM}-linux-amd64.tar.gz
  curl -O https://get.helm.sh/helm-${HELM}-linux-amd64.tar.gz.sha256sum
  sha256sum -c helm-${HELM}-linux-amd64.tar.gz.sha256sum
  tar xvfz helm-${HELM}-linux-amd64.tar.gz linux-amd64/helm
  sudo install ./linux-amd64/helm /usr/local/bin
  rm -f linux-amd64/helm
  rmdir linux-amd64
  rm -f helm-${HELM}-linux-amd64.tar.gz
  rm -f helm-${HELM}-linux-amd64.tar.gz.sha256sum
  # Install also Helm diff plugin
  if helm plugin list | grep -qc diff; then
    helm plugin update diff
  else
    helm plugin install https://github.com/databus23/helm-diff
  fi
}

install_kubectl() {
  # install system kubectl version (useful for e.g. bash autocompletion)
  sudo apt-get install kubernetes-client
  # install custom kubectl version (useful for development)
  cd ~/Downloads
  rm -f kubectl
  rm -f kubectl.sha256
  curl -LO https://dl.k8s.io/release/${KUBECTL}/bin/linux/amd64/kubectl
  curl -LO https://dl.k8s.io/release/${KUBECTL}/bin/linux/amd64/kubectl.sha256
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum -c
  sudo install ./kubectl /usr/local/bin
  rm -f kubectl
  rm -f kubectl.sha256
}

install_cr() {
  if [ -d ~/Downloads/chart-releaser ]; then
    cd ~/Downloads/chart-releaser
    git fetch origin
    git reset --hard origin/main
  else
    git clone https://github.com/helm/chart-releaser ~/Downloads/chart-releaser
  fi
  cd ~/Downloads/chart-releaser
  git reset --hard ${CR}
  git clean -d -ff -x
  cd cr
  go mod download
  go install ./...
}

install_lazygit() {
  go install github.com/jesseduffield/lazygit@${LAZYGIT}
}

install_kind() {
  go install sigs.k8s.io/kind@${KIND}
}

install_python() {
  VERSION=$1
  sudo apt build-dep -y python3.11
  cd ~/Downloads
  rm -f "Python-${VERSION}.tgz"
  sudo rm -rf "Python-${VERSION}"
  curl -O "https://www.python.org/ftp/python/${VERSION}/Python-${VERSION}.tgz"
  tar xvfz "Python-${VERSION}.tgz"
  cd "Python-${VERSION}"
  ./configure --enable-optimizations
  make -j 4
  sudo make altinstall
  rm -f "Python-${VERSION}.tgz"
  sudo rm -rf "Python-${VERSION}"
}

install_thinkfan() {
  if [ "$(hostname)" == "p1" ]; then
    sudo apt install -y thinkfan
    if [ ! -f /etc/modprobe.d/thinkpad_acpi.conf ]; then
      echo "options thinkpad_acpi fan_control=1" | sudo tee /etc/modprobe.d/thinkpad_acpi.conf
    fi
    sudo modprobe -rv thinkpad_acpi
    sudo modprobe -v thinkpad_acpi
    sudo cp -a "thinkfan/$(hostname)/thinkfan.conf" /etc/
    sudo systemctl enable --now thinkfan.service
    sudo systemctl restart thinkfan.service
  else
    echo "[ERROR] Unknown machine $(hostname)."
    exit 1
  fi
}

install_tlp() {
  if [ "$(hostname)" == "p1" ]; then
    sudo apt install -y tlp
    sudo cp -a "tlp/$(hostname)/tlp.conf" /etc/
    sudo systemctl enable --now tlp.service
    sudo systemctl restart tlp.service
  else
    echo "[ERROR] Unknown machine $(hostname)."
    exit 1
  fi
}

install_ufw() {
  sudo apt install -y ufw
  sudo systemctl enable --now ufw.service
  sudo ufw enable
  sudo ufw status verbose
}

install_slstatus() {
  sudo apt build-dep -y dwm
  if [ -d ~/Downloads/slstatus ]; then
    cd ~/Downloads/slstatus
    git fetch origin
    git reset --hard origin/master
  else
    git clone --recursive git://git.suckless.org/slstatus ~/Downloads/slstatus
  fi
  cp slstatus/config.h ~/Downloads/slstatus/
  cd ~/Downloads/slstatus
  sudo make install
}

install_dwm() {
  if [ -d ~/Downloads/dwm-flexipatch ]; then
    cd ~/Downloads/dwm-flexipatch
    git fetch origin
    git reset --hard origin/master
  else
    git clone https://github.com/bakkeby/dwm-flexipatch ~/Downloads/dwm-flexipatch
  fi

  cd ~/Downloads/dwm-flexipatch

  # 1) Select patches

  cp patches.def.h patches.h

  for patch in \
    ALWAYSCENTER_PATCH \
    BAR_SYSTRAY_PATCH \
    BAR_HIDEVACANTTAGS_PATCH \
    BSTACK_LAYOUT \
    CENTEREDFLOATINGMASTER_LAYOUT \
    CENTEREDMASTER_LAYOUT \
    CFACTS_PATCH \
    CYCLELAYOUTS_PATCH \
    DECK_LAYOUT \
    DWMC_PATCH \
    FOCUSDIR_PATCH \
    FOCUSONNETACTIVE_PATCH \
    GRIDMODE_LAYOUT \
    LOSEFULLSCREEN_PATCH \
    NET_CLIENT_LIST_STACKING_PATCH \
    NOBORDER_PATCH \
    NO_TRANSPARENT_BORDERS_PATCH \
    RESTARTSIG_PATCH \
    SEAMLESS_RESTART_PATCH \
    STACKER_PATCH \
    TOGGLEFULLSCREEN_PATCH \
    WINVIEW_PATCH; do
    sed -i "s|#define ${patch} 0|#define ${patch} 1|g" patches.h
  done

  # 2) Configure dwm

  # Copy default configuration
  cp config.def.h config.h

  # Use Super key
  sed -i "s|#define MODKEY Mod1Mask|#define MODKEY Mod4Mask|g" config.h

  # Terminal is Alacritty
  sed -i "s|\"st\"|\"alacritty\"|g" config.h

  # Configure next/previous
  sed -i 's| XK_j,| XK_n,|g' config.h
  sed -i 's| XK_k,| XK_p,|g' config.h

  # Configure gaps
  sed -i 's|int gappih         = 20;|int gappih         = 8;|g' config.h
  sed -i 's|int gappiv         = 10;|int gappiv         = 4;|g' config.h
  sed -i 's|int gappoh         = 10;|int gappoh         = 4;|g' config.h
  sed -i 's|int gappov         = 30;|int gappov         = 8;|g' config.h
  sed -i 's|int smartgaps_fact          = 1;|int smartgaps_fact          = 1;|g' config.h

  # Configure program runner
  sed -i 's|XK_p,          spawn,                  {.v = dmenucmd } }|XK_r,          spawn,                  {.v = dmenucmd } }|g' config.h

  # Resize with Control
  sed -i 's|MODKEY,                       XK_h,          setmfact,|MODKEY\|ControlMask,           XK_h,          setmfact,|g' config.h
  sed -i 's|MODKEY,                       XK_l,          setmfact,|MODKEY\|ControlMask,           XK_l,          setmfact,|g' config.h
  sed -i 's|MODKEY\|ShiftMask,             XK_h,          setcfact,|MODKEY\|ControlMask,            XK_j,          setcfact,|g' config.h
  sed -i 's|MODKEY\|ShiftMask,             XK_l,          setcfact,|MODKEY\|ControlMask,            XK_k,          setcfact,|g' config.h

  # Toggle fullscreen
  sed -i 's|XK_y,          togglefullscreen,|XK_z,          togglefullscreen,|g' config.h

  # Toggle bar
  sed -i 's|MODKEY,                       XK_b,          togglebar,|MODKEY\|ShiftMask,             XK_b,          togglebar,|g' config.h

  # Switch off toggling gaps on Super-0
  sed -i 's|{ MODKEY\|Mod4Mask,              XK_0,          togglegaps,             {0} },|// { MODKEY\|Mod4Mask,              XK_0,          togglegaps,             {0} },|g' config.h
  sed -i 's|{ MODKEY\|Mod4Mask\|ShiftMask,    XK_0,          defaultgaps,            {0} },|// { MODKEY\|Mod4Mask\|ShiftMask,    XK_0,          defaultgaps,            {0} },|g' config.h

  # Jump around clients
  sed -i 's|MOD, XK_w,     ACTION##stack, {.i = 0 }|MOD, XK_a,     ACTION##stack, {.i = 0 }|g' config.h
  sed -i 's|MOD, XK_e,     ACTION##stack, {.i = 1 }|MOD, XK_b,     ACTION##stack, {.i = 1 }|g' config.h
  sed -i 's|MOD, XK_a,     ACTION##stack, {.i = 2 }|MOD, XK_c,     ACTION##stack, {.i = 2 }|g' config.h
  sed -i 's|MOD, XK_z,     ACTION##stack, {.i = -1 }|MOD\|ShiftMask, XK_a,     ACTION##stack, {.i = -1 }|g' config.h

  # Modify shortcut for the floating layout
  sed -i 's|{ MODKEY,                       XK_f,          setlayout,              {.v = &layouts\[1\]} }|{ MODKEY\|ShiftMask,             XK_f,          setlayout,              {.v = \&layouts\[1\]} }|g' config.h

  # Configure master-stack area proportions
  sed -i 's|mfact     = 0.55;|mfact     = 0.55;|g' config.h

  # Window rules
  sed -i 's|RULE(.class = "Gimp", .tags = 1 << 4)|// RULE(.class = "Gimp", .tags = 1 << 4)|g' config.h
  sed -i 's|RULE(.class = "Firefox", .tags = 1 << 7)| // RULE(.class = "Firefox", .tags = 1 << 7)|g' config.h

  # Configure colours: gruvbox theme
  # (generate list via `grep 'color.*#' config.def.h | awk '{print $NF}' | sort -u`)
  sed -i 's|#000033|#000003|g' config.h
  sed -i 's|#000044|#000044|g' config.h
  sed -i 's|#003300|#003300|g' config.h
  sed -i 's|#003333|#003333|g' config.h
  sed -i 's|#004400|#004400|g' config.h
  sed -i 's|#004444|#004444|g' config.h
  sed -i 's|#005500|#005500|g' config.h
  sed -i 's|#005555|#005555|g' config.h
  sed -i 's|#005577|#000000|g' config.h # 3b4439 32302f
  sed -i 's|#115577|#115577|g' config.h
  sed -i 's|#116688|#116688|g' config.h
  sed -i 's|#117799|#117799|g' config.h
  sed -i 's|#212171|#212171|g' config.h
  sed -i 's|#222222|#000000|g' config.h #000000 #282828
  sed -i 's|#227799|#227799|g' config.h
  sed -i 's|#330000|#330000|g' config.h
  sed -i 's|#330033|#330033|g' config.h
  sed -i 's|#333300|#333300|g' config.h
  sed -i 's|#440000|#440000|g' config.h
  sed -i 's|#440044|#440044|g' config.h
  sed -i 's|#444400|#444400|g' config.h
  sed -i 's|#444444|#3a3735|g' config.h
  sed -i 's|#506600|#506600|g' config.h
  sed -i 's|#507711|#507711|g' config.h
  sed -i 's|#508822|#508822|g' config.h
  sed -i 's|#550000|#550000|g' config.h
  sed -i 's|#550055|#550055|g' config.h
  sed -i 's|#555500|#555500|g' config.h
  sed -i 's|#664C67|#664C67|g' config.h
  sed -i 's|#77547E|#d3869b|g' config.h
  sed -i 's|#894B9F|#894B9F|g' config.h
  sed -i 's|#b96600|#b96600|g' config.h
  sed -i 's|#b97711|#b97711|g' config.h
  sed -i 's|#b98822|#b98822|g' config.h
  sed -i 's|#bbbbbb|#928374|g' config.h
  sed -i 's|#db8fd9|#db8fd9|g' config.h
  sed -i 's|#eeeeee|#89b482|g' config.h
  sed -i 's|#ff0000|#ea6962|g' config.h
  sed -i 's|#FFF7D4|#ddc7a1|g' config.h

  # Fix some colours after general replacement
  sed -i 's|selbordercolor\[\]             = "#......";|selbordercolor[]             = "#6d9068";|g' config.h # 5f6e5c 6d9068
  sed -i 's|tagsselfgcolor\[\]             = "#......";|tagsselfgcolor[]             = "#89b482";|g' config.h
  sed -i 's|tagsselbgcolor\[\]             = "#......";|tagsselbgcolor[]             = "#000000";|g' config.h
  sed -i 's|titleselfgcolor\[\]            = "#......";|titleselfgcolor[]            = "#89b482";|g' config.h
  sed -i 's|titleselbgcolor\[\]            = "#......";|titleselbgcolor[]            = "#000000";|g' config.h

  # Configure multimedia key, directional keys, application keys, layout keys
  sed -i "1i #include <X11/XF86keysym.h> \n" config.h
  sed -i "2i static const char *windowmenucmd[] = { \"x1-windowmenu\", NULL};\n" config.h
  sed -i "3i static const char *windowmenubrowsercmd[] = { \"x1-windowmenu\", \"firefox\", \"--select-first\", NULL};\n" config.h
  sed -i "4i static const char *windowmenuterminalcmd[] = { \"x1-windowmenu\", \"Alacritty\", \"--select-first\", NULL};\n" config.h
  sed -i "/^static const Key keys\[\] = {/a \    \
    { 0, XF86XK_AudioMute,          spawn,          SHCMD(\"amixer set Master toggle\") }, \n    \
    { 0, XF86XK_AudioRaiseVolume,   spawn,          SHCMD(\"amixer set Master 5%+\") }, \n    \
    { 0, XF86XK_AudioLowerVolume,   spawn,          SHCMD(\"amixer set Master 5%-\") }, \n    \
    { 0, XF86XK_AudioMicMute,       spawn,          SHCMD(\"amixer set Capture toggle\") }, \n    \
    { 0, XF86XK_MonBrightnessDown,  spawn,          SHCMD(\"light -U 5\") }, \n    \
    { 0, XF86XK_MonBrightnessUp,    spawn,          SHCMD(\"light -A 5\") }, \n    \
    { MODKEY,                       XK_h,          focusdir,               {.i = 0 } }, \n    \
    { MODKEY,                       XK_l,          focusdir,               {.i = 1 } }, \n    \
    { MODKEY,                       XK_k,          focusdir,               {.i = 2 } }, \n    \
    { MODKEY,                       XK_j,          focusdir,               {.i = 3 } }, \n    \
    { MODKEY,                       XK_w,          spawn,                  {.v = windowmenucmd } }, \n    \
    { MODKEY,                       XK_f,          spawn,                  {.v = windowmenubrowsercmd } }, \n    \
    { MODKEY,                       XK_x,          spawn,                  {.v = windowmenuterminalcmd } }, \n    \
    { MODKEY|ShiftMask,             XK_t,          setlayout,              {.v = &layouts[3]} }, // bstack \n    \
    { MODKEY,                       XK_y,          setlayout,              {.v = &layouts[4]} }, // centeredmaster \n    \
    { MODKEY|ShiftMask,             XK_y,          setlayout,              {.v = &layouts[5]} }, // centeredfloatingmaster \n    \
    { MODKEY,                       XK_e,          setlayout,              {.v = &layouts[6]} }, // deck \n    \
    { MODKEY,                       XK_g,          setlayout,              {.v = &layouts[7]} }, // grid \n    \
    " config.h

  make clean
  sudo make install
  kill -HUP "$(pidof dwm)"
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
  sudo apt install -y brave-browser
  # Prefer Brave browser
  BROWSER="" xdg-settings set default-web-browser brave-browser.desktop
}

install_librewolf() {
  sudo apt install -y extrepo
  sudo extrepo enable librewolf
  sudo apt update -y && sudo apt install -y librewolf
  # Prefer LibreWolf browser
  BROWSER="" xdg-settings set default-web-browser brave-browser.desktop
}

install_floorp() {
  curl -fsSL https://ppa.floorp.app/KEY.gpg | sudo gpg --dearmor -o /usr/share/keyrings/Floorp.gpg
  sudo curl -sS --compressed -o /etc/apt/sources.list.d/Floorp.list "https://ppa.floorp.app/Floorp.list"
  sudo apt update
  sudo apt install floorp
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
  echo "  backports     Install backports packages"
  echo "  rustup        Install rustup"
  echo "  alacritty     Install alacritty"
  echo "  cr            Install chart-releaser"
  echo "  delta         Install delta"
  echo "  dwm           Install dwm"
  echo "  gtktheme      Install GTK theme"
  echo "  lazygit       Install lazygit"
  echo "  mons          Install mons"
  echo "  nerdfonts     Install nerdfonts"
  echo "  nvim          Install nvim"
  echo "  slstatus      Install slstatus"
  echo "  starship      Install starship"
  echo "Targets (apps):"
  echo "  docker        Install docker"
  echo "  helm          Install helm"
  echo "  kind          Install kind"
  echo "  kubectl       Install kubectl"
  echo "  latex         Install LaTeX (texlive)"
  echo "  locales       Install and generate en_GB.UTF-8 locale"
  echo "  mise          Install mise"
  echo "  python3.8     Install python3.8"
  echo "  python3.9     Install python3.9"
  echo "  python3.10    Install python3.10"
  echo "  python3.12    Install python3.12"
  echo "  python3.13    Install python3.13"
  echo "Targets (optional):"
  echo "  brave         Install brave"
  echo "  firefox       Configure firefox"
  echo "  floorp        Install floorp"
  echo "  helix         Install helix"
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
alacritty) install_alacritty ;;
backports) install_backports ;;
base-cli) install_base_cli ;;
base-gui) install_base_gui ;;
brave) install_brave ;;
cr) install_cr ;;
delta) install_delta ;;
docker) install_docker ;;
dwm) install_dwm ;;
firefox) configure_firefox ;;
floorp) install_floorp ;;
gtktheme) install_gtktheme ;;
helix) install_helix ;;
helm) install_helm ;;
kind) install_kind ;;
kubectl) install_kubectl ;;
latex) install_latex ;;
lazygit) install_lazygit ;;
librewolf) install_librewolf ;;
locales) install_locales ;;
mise) install_mise ;;
mons) install_mons ;;
nerdfonts) install_nerdfonts ;;
nvim) install_nvim ;;
oc) install_oc ;;
python3.10) install_python ${PY310} ;;
python3.12) install_python ${PY312} ;;
python3.13) install_python ${PY313} ;;
python3.8) install_python ${PY38} ;;
python3.9) install_python ${PY39} ;;
rustup) install_rustup ;;
slstatus) install_slstatus ;;
starship) install_starship ;;
thinkfan) install_thinkfan ;;
tlp) install_tlp ;;
ufw) install_ufw ;;
*) echo "[ERROR] Invalid argument '$arg'. Exiting." && help && exit 1 ;;
esac
