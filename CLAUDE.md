# Project context

Setting up a daily-driver Linux desktop on an **Acer Swift X** laptop ahead
of an international move to Korea. This file exists so Claude Code doesn't
have to rediscover decisions already made (or re-suggest paths already
tried and rejected) across sessions.

## Current stack (decided, don't re-litigate without reason)

- **Distro**: CachyOS (Arch-based). **Previously tried NixOS + niri —
  abandoned.** Debugging NixOS's declarative model *and* NVIDIA *and* a
  brand-new Wayland shell simultaneously was too much friction at once.
  Don't suggest going back to Nix/flakes/home-manager unless explicitly asked.
- **Compositor**: Hyprland, configured **floating-by-default**
  (`windowrulev2 = float, class:.*`). The person specifically wants
  Windows/KDE-style floating window management, not tiling. niri was tried
  first and rejected for this reason (niri's tiling isn't optional).
- **Shell/bar**: Noctalia (Quickshell-based). **Caelestia was seriously
  considered and rejected** — it's officially Hyprland-only, and the
  unofficial niri fork had no Nix/Arch packaging and an abandoned upstream.
  Even after moving to Hyprland (which would unlock real Caelestia), the
  person chose to stick with Noctalia — it's more actively developed and
  natively supports more compositors. Don't suggest switching to Caelestia
  again unless the person raises it.
- **Login greeter**: **SDDM** (2026-07-25, reversed from noctalia-greeter).
  noctalia-greeter was tried first — matched Noctalia's look in theory,
  but rendered stretched/wrong in practice (its own compositor instance
  doesn't inherit the NVIDIA/`QT_QUICK_BACKEND` env vars this laptop
  needs — same rendering-issue family as the Noctalia-shell-invisible bug
  below, just manifesting differently) and its setup required a
  hand-paste config step from a script whose exact printed path varied by
  build, which couldn't be safely automated. SDDM is also what CachyOS's
  installer already enables by default, so this now works *with* the
  installer instead of fighting it. Don't re-suggest noctalia-greeter
  unless the person raises it again.
  - Theme: `sddm-silent-theme` (SilentSDDM) — actively maintained, ships a
    `catppuccin-mocha.conf` preset. Activated via
    `/etc/sddm.conf.d/theme.conf` (`Current=silent`) in `setup.sh`; the
    exact key to pick the Mocha preset specifically wasn't independently
    confirmed (see NOTES.md #1).
  - **Historical note**: an earlier version of `setup.sh` had a bug where
    it never actually disabled SDDM before enabling greetd, despite this
    file already documenting that they conflict — both stayed enabled,
    and SDDM silently won, which was the actual cause of a "boots to a
    fallback login, DE never loads" bug hit once. Moot now that SDDM is
    the intended greeter again, but if greetd ever comes back for some
    reason, remember to disable SDDM first.
- **Launcher**: Vicinae (Raycast port, AUR: `vicinae-bin`) is the *primary*
  launcher, bound to `SUPER+Space`. Noctalia's own launcher is bound to
  `SUPER+A` as a secondary/backup, not the main one. Vicinae is
  client/server — confirmed via docs.vicinae.com/quickstart/hyprland that
  `exec-once = vicinae server` (not bare `vicinae`) plus
  `bind = SUPER, SPACE, exec, vicinae toggle` is the correct pair. Running
  the bare binary in exec-once (an earlier bug) never started the server,
  so the toggle bind silently did nothing.
- **Shell**: fish, with fisher as plugin manager (fzf-fish, done plugins).
- **Theme**: Catppuccin Mocha. Default niri/Hyprland focus-ring blue was
  explicitly disliked — use the mauve accent (`#cba6f7`) instead of bright
  blue wherever a border/accent color is configurable.

## Hardware specifics

- **Laptop**: Acer Swift X
- **GPU**: Hybrid/Optimus — Intel or AMD CPU + discrete NVIDIA GPU (RTX
  30/40-series range). Person has had recurring NVIDIA driver problems on
  this machine historically — be extra careful here.
  - Needed env vars for Hyprland: `LIBVA_DRIVER_NAME=nvidia`,
    `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `NVD_BACKEND=direct`,
    `WLR_NO_HARDWARE_CURSORS=1`
  - **Known bug already hit once**: Noctalia/Quickshell renders completely
    invisibly (process runs fine, zero errors in logs, nothing draws) on
    this NVIDIA setup unless Qt Quick is forced to software rendering
    (`QT_QUICK_BACKEND=software` fixed it on the niri attempt). If Noctalia
    is invisible again on Hyprland, try this same fix first before deep
    debugging — confirmed root cause last time via
    `QT_QUICK_BACKEND=software noctalia-shell` in a terminal.
  - `prime-run <command>` is bundled by CachyOS by default for launching
    specific apps on the dGPU.
- **Display**: 1920x1080 (Full HD panel)
- **Fingerprint sensor**: chip unknown — check `lsusb` before assuming
  which driver stack is needed (Goodix/Synaptics "Prometheus"/ELAN all
  behave differently; Synaptics needs `python-validity`, not plain fprintd).
  `setup.sh` prints the vendor-ID table and greps `lsusb` automatically.
  **Known bug already hit once**: NOTES.md previously said
  `sudo fprintd-enroll` — that enrolls a fingerprint for the *root*
  account, not the user's own login, so nothing the user's session or
  sudo prompt checks against ever matches. Always run plain
  `fprintd-enroll` (no sudo) as the user being enrolled; `setup.sh` now
  does this.
- **Power/GPU-switching tooling**: explicitly declined (2026-07-25) despite
  being a hybrid-NVIDIA laptop ahead of international travel — don't
  re-suggest `envycontrol`/`power-profiles-daemon` unless the person
  raises battery life as an actual problem.
- **Keyboard**: physical layout is **French AZERTY** (person is French,
  relocating to Korea). Keyboard layout config should be `us,fr,kr` with a
  toggle (not just `us,kr` — AZERTY going missing entirely was a real bug
  hit once already).

## Disk layout (dual boot with Windows)

Windows was installed first (AtlasOS-debloated Windows 11), and its
partitions must be left untouched:
- `nvme0n1p1` — 200MiB FAT32 — Windows' own ESP — **do not touch**
- `nvme0n1p2` — 16MiB — Microsoft Reserved Partition — **do not touch**
- `nvme0n1p3` — 358GB NTFS — Windows itself — **do not touch**
- `nvme0n1p4` — 853MB NTFS — Windows Recovery Environment — **do not touch**
- `nvme0n1p5` (or new partitions carved from its space) — CachyOS lives
  here. CachyOS needed its **own separate ESP, minimum 4096MiB** (its
  installer rejected reusing/sharing the tiny Windows ESP — CachyOS's
  multi-kernel-variant boot entries need more room than Windows' 200MB
  ever provided). Root partition (ext4 or btrfs) takes the remaining space.
- Bootloader: **Limine** (CachyOS installer default) — should auto-detect
  Windows since it's a separate ESP scan, not shared-partition dependent
  like the old single-ESP setup was.

Windows-side dual-boot fixes already applied: Fast Startup disabled,
`RealTimeIsUniversal=1` registry fix for clock skew, BitLocker left off.

## Person's known preferences (don't relitigate)

- Boycotts Spotify — uses **Echoes/Echo Music** (open-source YouTube Music
  client, Flutter-based). MPRIS support unconfirmed — test with
  `playerctl status` before assuming the media widget will show it.
- Dislikes atuin's default up-arrow/Ctrl+R takeover — disabled via
  `atuin init fish --disable-up-arrow --disable-ctrl-r`; fzf-fish owns
  Ctrl+R history search instead.
- CLI tool favorites (already installed, keep): eza, zoxide, fastfetch
  (particularly liked), atuin, bat, ripgrep, fzf, dust (particularly
  liked), bottom, procs, git-delta, tokei, hyperfine, just, Ghostty terminal.
- Wants Dolphin as file manager (native on Arch, no extra config needed
  beyond installing `dolphin` + `ark`).
- Wants clipboard tooling: `wl-clipboard` + `cliphist`, plus a fish `clip`
  function wrapping `wl-copy` for piping command output to clipboard.
- Cursor: Bibata-Modern-Ice — was previously "big and doesn't change on
  hover," which is what a properly set cursor theme fixes.
- Wants coherent window decoration — `prefer-no-csd`-equivalent thinking
  applies; avoid mismatched per-app titlebars.
- Wants `SUPER+L` bound to lock screen — Noctalia's documented IPC command
  is `qs -c noctalia-shell ipc call lockScreen lock`.
- Screenshots/screen recording: **Spectacle** (KDE, works fine outside
  Plasma over the existing xdg-desktop-portal-hyprland + PipeWire stack).
  Chosen explicitly over hyprshot/grimblast because recording was wanted
  alongside screenshots, not just region capture. `Print` opens the full
  picker (screenshot or recorder tab); `SUPER+Print` is a no-GUI region
  grab straight to clipboard.
- Media keys (play/pause/next/prev) bound via `playerctl`, for Echoes/MPRIS.

## Gaming / Windows side (separate from Linux config, already delivered)

AtlasOS install guide followed, with the caveat to **skip disabling
Core Isolation/VBS/Secure Boot mitigations** if playing anything with
kernel-level anti-cheat (Vanguard/Valorant, some EAC titles) — those
require VBS to launch at all now.

## Files in this repo

- `setup.sh` — all package installs (paru), SDDM setup, config copying,
  fisher, fingerprint/PAM wiring, theming
- `hypr/hyprland.conf` — floating-by-default, Noctalia's official
  appearance block, IPC keybinds, NVIDIA env vars
- `hypr/hypridle.conf` — optional auto-lock on idle via Noctalia's lock IPC
- `fish/config.fish` — aliases, abbreviations, atuin flags, clip function
- `NOTES.md` — manual GUI/CLI steps that can't be scripted

## Known unconfirmed items (verify, don't assume)

- SilentSDDM's exact config key for selecting the `catppuccin-mocha.conf`
  preset specifically (`setup.sh` only activates the theme itself, not
  that preset — see NOTES.md #1)
- GTK theme *application* is a one-time `nwg-look` GUI step (NOTES.md #2)
  even though the Catppuccin Mocha packages and Papirus mauve folder
  accent are installed/applied automatically by `setup.sh`

## Known active issue: duplicate boot entries (as of 2026-07-25)

Multiple Limine installs/EFI boot entries have accumulated across
iterations (at least one entry of unknown origin, count unconfirmed).
**Why**: repeated CachyOS/Limine (re)installs during earlier
troubleshooting likely each registered a new UEFI NVRAM entry and/or ESP
directory without removing the previous one — this is separate from and
unrelated to the SDDM/greetd conflict above (that was a systemd
enabled-unit problem, not a bootloader/EFI problem).
**How to apply**: don't suggest a full CachyOS reinstall to fix this —
it's an EFI NVRAM/ESP cleanup problem, not disk corruption, and
reinstalling risks *adding* another duplicate entry rather than removing
the stale ones. Diagnose with `efibootmgr -v` and by inspecting the ESP
contents before deleting anything, and never touch `nvme0n1p1` (Windows'
own ESP — see disk layout below). Status: diagnosis in progress, not yet
resolved as of this writing.
