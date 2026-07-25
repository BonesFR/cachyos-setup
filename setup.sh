#!/usr/bin/env bash
# CachyOS + Hyprland (floating-by-default) + Noctalia — full setup
# Run after a fresh CachyOS install with the "no DE" / minimal option, or
# on top of an existing install if you're just adding Hyprland.
#
# Review each section before running — this isn't meant to be blindly piped.
# Safe to re-run: every step below is idempotent (package installs use
# --needed, file copies back up existing files, PAM edits check before
# inserting, service enables are no-ops if already enabled).

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "== Hyprland + core Wayland session =="
paru -S --needed \
  hyprland hyprpolkitagent xdg-desktop-portal-hyprland \
  qt5-wayland qt6-wayland qt5ct qt6ct kvantum \
  pipewire wireplumber pipewire-audio pipewire-pulse

echo "== Noctalia shell (bar/panels only — greeter is SDDM, see below) =="
paru -S --needed noctalia-shell accountsservice

echo "== CLI toolstack (carried over from the whole earlier conversation) =="
paru -S --needed \
  eza zoxide fastfetch atuin bat ripgrep fzf dust bottom procs \
  git-delta tokei hyperfine just ghostty fish starship \
  wl-clipboard cliphist swww

echo "== Launcher, file manager, fingerprint =="
paru -S --needed vicinae-bin dolphin ark fprintd

echo "== Screenshots / screen recording, media control =="
paru -S --needed spectacle playerctl

echo "== Theming: Catppuccin Mocha (GTK/Qt coherence) + Bibata cursor =="
paru -S --needed \
  bibata-cursor-theme-bin nwg-look papirus-icon-theme \
  catppuccin-gtk-theme-mocha papirus-folders-catppuccin-git
# Mauve accent on folder icons, matching the mauve focus/border accent used
# elsewhere instead of Papirus's default blue.
sudo papirus-folders -C cat-mocha-mauve --theme Papirus-Dark || true

echo "== Networking / Bluetooth (harmless if already set up by the installer) =="
paru -S --needed networkmanager bluez bluez-utils
sudo systemctl enable --now NetworkManager bluetooth

echo "== Fonts (Nerd Font glyphs for eza --icons / starship prompt symbols) =="
paru -S --needed ttf-jetbrains-mono-nerd noto-fonts-emoji

echo "== GPU: NVIDIA Optimus =="
paru -S --needed nvidia-open-dkms nvidia-utils
# prime-run is bundled by CachyOS by default — launch specific apps on the
# dGPU with `prime-run <command>`.

echo "== Korea prep: fonts + input method =="
paru -S --needed noto-fonts-cjk ttf-pretendard fcitx5 fcitx5-hangul fcitx5-gtk fcitx5-qt

echo "== Fish as default shell =="
chsh -s "$(which fish)"

echo "== fisher (fish plugin manager) + plugins =="
fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
fish -c 'fisher install PatrickF1/fzf.fish'
fish -c 'fisher install franciscolourenco/done'

echo "== Copying configs into place (backing up anything already there) =="
copy_config() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && ! cmp -s "$src" "$dest"; then
    cp "$dest" "$dest.bak.$(date +%s)"
    echo "  backed up existing $dest"
  fi
  cp "$src" "$dest"
  echo "  installed $dest"
}
copy_config "$REPO_DIR/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
copy_config "$REPO_DIR/config.fish" "$HOME/.config/fish/config.fish"
if paru -Qq hypridle &>/dev/null; then
  copy_config "$REPO_DIR/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
else
  echo "  hypridle not installed, skipping hypridle.conf (paru -S hypridle if you want auto-lock)"
fi

echo "== SDDM greeter (Catppuccin Mocha via SilentSDDM) =="
# Went with SDDM over noctalia-greeter: CachyOS's installer already enables
# SDDM by default, so this fights the installer instead of it; SDDM also
# has a real theme ecosystem (SilentSDDM ships a catppuccin-mocha.conf
# preset) instead of noctalia-greeter's "print a config block, hand-paste
# it, hope the session wrapper path matches your build" setup — and
# noctalia-greeter's own compositor doesn't inherit the NVIDIA/Qt Quick
# env vars this laptop needs, which is the likely cause of the "stretched
# out" rendering seen when it was tried.
paru -S --needed sddm sddm-silent-theme
# Undo greetd if an earlier run of this script set it up.
if systemctl is-enabled greetd &>/dev/null; then
  sudo systemctl disable --now greetd
  echo "  disabled greetd (leftover from the noctalia-greeter attempt)"
fi
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=silent\n' | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
sudo systemctl enable sddm

echo "== Fingerprint enrollment =="
# Run as YOUR user, not root — `sudo fprintd-enroll` enrolls a fingerprint
# for the root account, which is useless for unlocking your own session or
# authenticating your own sudo prompts. fprintd talks to the sensor over
# D-Bus/polkit and doesn't need root itself.
echo "  Sensor check (compare against lsusb):"
echo "    Goodix    -> vendor 27c6"
echo "    Synaptics -> vendor 06cb (needs python-validity instead of fprintd — different driver stack)"
echo "    ELAN      -> vendor 04f3"
lsusb | grep -iE "27c6|06cb|04f3|fingerprint|goodix|synaptics|elan" || echo "    (no obviously-matching device seen in lsusb — enrollment may fail below)"
echo "  Enrolling right finger index on your own account (follow the prompts)..."
if fprintd-enroll; then
  add_fprintd_pam() {
    local file="$1"
    if ! grep -q "pam_fprintd.so" "$file"; then
      sudo sed -i '0,/^auth/s//auth       sufficient   pam_fprintd.so\nauth/' "$file"
      echo "  added pam_fprintd.so to $file"
    else
      echo "  $file already has pam_fprintd.so, skipping"
    fi
  }
  add_fprintd_pam /etc/pam.d/sudo
  add_fprintd_pam /etc/pam.d/login
else
  echo "  fprintd-enroll failed — check the sensor table above, this chip may need"
  echo "  a different driver (e.g. python-validity for Synaptics 06cb) instead of fprintd."
fi

echo ""
echo "================================================================"
echo "Packages, services, and configs are done. Two things left:"
echo ""
echo "1. SilentSDDM ships several presets (configs/catppuccin-mocha.conf"
echo "   among them) — this script only activated the theme, it didn't"
echo "   confirm the exact key that picks that specific preset (varies by"
echo "   theme version, wasn't independently verified). Check:"
echo "     cat /usr/share/sddm/themes/silent/README.md 2>/dev/null || true"
echo "   and the AUR page for sddm-silent-theme if that file isn't there."
echo "   Also sanity check the Hyprland session even shows up on the SDDM"
echo "   login screen: it should, since the hyprland package ships"
echo "   /usr/share/wayland-sessions/hyprland.desktop itself — if it's"
echo "   missing from the session picker, check that file exists."
echo ""
echo "2. GTK theme selection: run 'nwg-look' once and pick the Catppuccin"
echo "   Mocha GTK theme + Papirus (Catppuccin folders) icon theme that were"
echo "   just installed — this is a one-time GUI picker, not scriptable."
echo "================================================================"
