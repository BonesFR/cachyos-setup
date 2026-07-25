# CachyOS + Hyprland + Noctalia — manual steps

Run `setup.sh` first. It now handles package installs, SDDM setup (theme
+ enable), copying configs into `~/.config`, fisher + plugins, fingerprint
enrollment + PAM wiring, GTK icon/folder accent colors, and
Bluetooth/NetworkManager. Two things are left because scripting them
blindly risks a config that can't boot, or because they're one-time GUI
choices — safety/judgment calls, not laziness:

## 0. Hyprland uses Lua config now, not `hyprland.conf` — read this first

This repo used to ship a flat `hyprland.conf`. **It's gone.** Hyprland
0.55+ (0.56.0 confirmed on this machine) checks once at startup: if
`~/.config/hypr/hyprland.lua` exists, it's used *exclusively* — no
merging, no fallback to `hyprland.conf`, and critically **no error** if a
`hyprland.conf` also happens to exist unused right next to it. That cost
an entire debugging session: every edit to the old `hyprland.conf` was
silently inert (git-synced correctly, byte-for-byte correct content,
zero `hyprctl configerrors`) because Hyprland was never reading it at
all — it was reading CachyOS's own auto-deployed Lua config the whole
time (`noctalia-shell`'s package ships a full `hyprland.lua` +
`~/.config/hypr/config/*.lua` structure via `/etc/skel`, upstream:
github.com/CachyOS/cachyos-hypr-noctalia).

Fix: work with that structure instead of fighting it (same reasoning as
the SDDM switch). `setup.sh` now deploys `hypr-config/{inputs,binds,
windowrules,variables}.lua` to `~/.config/hypr/config/` and
`hypr-config/uwsm-env` to `~/.config/uwsm/env`, each a copy of the
upstream CachyOS file with only the specific lines this person asked to
change — diff against the actual upstream files on that GitHub repo if
CachyOS updates their defaults and this drifts.

**After deploying: fully log out and back in, not just `hyprctl
reload`.** `~/.config/uwsm/env` (NVIDIA, fcitx5, cursor env vars) is only
read at session start; config/*.lua changes (keybinds, layout, floating)
do hot-reload.

Also: the SDDM session list has both a plain **Hyprland** entry and a
**Hyprland (uwsm managed)** one. Both were tested and both ignore
`hyprland.conf` identically (this is a Hyprland-level config-loading
rule, not a uwsm quirk) — either works with the current Lua-based setup.

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

## 3b. hyprbars titlebar plugin — verify it actually loaded

`setup.sh` runs `hyprpm add ... && hyprpm enable hyprbars`, guarded so a
build failure doesn't abort the rest of the script (plugin ABI mismatches
against the exact installed Hyprland version are the most common failure
mode for any Hyprland plugin). Check it actually worked:
```sh
hyprctl plugins list
```
If `hyprbars` isn't listed, try `hyprpm update` then `hyprpm enable
hyprbars` manually — the `hl.config`/`hl.plugin.hyprbars` calls in
`windowrules.lua` are inert (not an error) if the plugin never loaded, so
this fails silently from the config's point of view.

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
- Korea prep (fonts, fcitx5-hangul, locale) — packages in `setup.sh`, IM
  env vars in `hypr-config/uwsm-env`; just confirm the toggle key works
  after first login (`kb_options` in `hypr-config/inputs.lua` uses
  Alt+Shift to cycle fr/us/kr — not Win+Space, that collides with
  Vicinae's toggle bind)

None of that was NixOS-specific, so nothing there needs redoing.
