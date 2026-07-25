# CachyOS + Hyprland + Noctalia — manual steps

Run `setup.sh` first. It now handles package installs, SDDM setup (theme
+ enable), copying configs into `~/.config`, fisher + plugins, fingerprint
enrollment + PAM wiring, GTK icon/folder accent colors, and
Bluetooth/NetworkManager. Two things are left because scripting them
blindly risks a config that can't boot, or because they're one-time GUI
choices — safety/judgment calls, not laziness:

## 1. SDDM theme preset (likely one-line config check)

Greeter is **SDDM**, not noctalia-greeter — switched after noctalia-greeter
turned out stretched/oddly rendered in practice (its compositor doesn't
inherit the NVIDIA/Qt-Quick env vars this laptop needs) and required a
hand-paste setup step that couldn't be automated safely. SDDM was already
CachyOS's installer default, so this is now working with the installer
instead of against it.

`setup.sh` installs `sddm-silent-theme` (SilentSDDM — actively maintained,
ships a `catppuccin-mocha.conf` preset) and activates it via
`/etc/sddm.conf.d/theme.conf`. The exact key to select the Mocha preset
specifically (versus SilentSDDM's default look) wasn't independently
confirmed — check `/usr/share/sddm/themes/silent/README.md` after install.

Also confirm the Hyprland session actually shows up on the SDDM login
screen — it should, since the `hyprland` package ships
`/usr/share/wayland-sessions/hyprland.desktop` itself, but worth a glance
at `ls /usr/share/wayland-sessions/` if it's missing from the picker.

## 2. GTK theme selection (one-time GUI picker)

`setup.sh` installs `catppuccin-gtk-theme-mocha`, `nwg-look`, and sets the
Papirus folder accent to mauve automatically. GTK's active theme is still
a per-user setting stored via `gsettings`/`~/.config/gtk-3.0/settings.ini`,
which only a GUI picker can sensibly set without guessing your intent:

```sh
nwg-look
```
Pick the Catppuccin Mocha GTK theme and Papirus-Dark icon theme there.
Official theming reference if you want to go deeper (fonts, Qt style):
https://docs.noctalia.dev/v4/theming/program-specific/gtk-qt/

## 3. Fingerprint: confirmed unsupported by mainline fprintd

Chip identified: **EgisTec/LighTuning EH575** (USB `1c7a:0575`). This is
**not supported by mainline libfprint**, so `fprintd-enroll` reporting "no
device" isn't a config problem — `setup.sh` now detects vendor `1c7a` and
skips the attempt entirely instead of failing pointlessly.

Community options exist, unverified:
- AUR `open-fprintd-eh575` — conflicts with plain `fprintd`, python +
  opencv based, isolated `/opt` install. Read the PKGBUILD/comments before
  trusting it for login/sudo auth.
- https://github.com/Animeshz/EgisTec-EH575 — the reverse-engineering
  effort this chip's support is based on; last documented as still WIP
  against libfprint, not a turnkey package.

Not wired into `setup.sh` automatically — this is a "does it actually work
reliably enough to gate sudo on" judgment call, not something to script
blindly.

## 4. Confirm your NVIDIA bus setup

Hyprland now auto-detects the monitor, so that manual step is gone. Only
this is worth a sanity check after first login:
```sh
lspci | grep -E "VGA|3D"   # confirm both GPUs are detected
```

## 5. Everything else from earlier in this conversation still applies

- Dual-boot fixes (Fast Startup, clock skew, no BitLocker) — unchanged
- AtlasOS + gaming tools on the Windows side — unchanged
- Limine as bootloader (CachyOS installer offers it directly) — unchanged
- Korea prep (fonts, fcitx5-hangul, locale) — packages and IM env vars are
  now both in place (`setup.sh` + `hyprland.conf`); just confirm the
  toggle key works after first login (kb_options uses Win+Space to cycle
  us/fr/kr)

None of that was NixOS-specific, so nothing there needs redoing.
