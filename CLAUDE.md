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
  (`hl.window_rule({ match = { class = ".*" }, float = true })` in
  `config/windowrules.lua` — see the Lua-config section below, this used
  to be `windowrulev2 = float, class:.*` in a flat `hyprland.conf` that no
  longer exists). The person specifically wants Windows/KDE-style floating
  window management, not tiling. niri was tried first and rejected for
  this reason (niri's tiling isn't optional).
- **⚠️ Hyprland config format: Lua, not `hyprland.conf`** (discovered
  2026-07-25 after a very long debugging session). Hyprland 0.55+ checks
  *once* at startup: if `~/.config/hypr/hyprland.lua` exists, it's used
  exclusively — no merge with `hyprland.conf`, no error if a
  `hyprland.conf` sits there unused. `noctalia-shell`'s package
  auto-deploys a full Lua config (`hyprland.lua` requiring
  `~/.config/hypr/config/{animations,autostart,binds,colors,decorations,
  environment,inputs,misc,monitors,variables,windowrules,workspaces}.lua`)
  via `/etc/skel`, upstream: github.com/CachyOS/cachyos-hypr-noctalia.
  **This repo no longer ships a `hyprland.conf` at all** — it ships
  `hypr-config/{inputs,binds,windowrules,variables}.lua` +
  `hypr-config/uwsm-env`, each a copy of the real upstream CachyOS file
  with only the specific lines changed (see "Files in this repo" below).
  If CachyOS updates its upstream defaults, diff against the real repo
  before assuming these are stale.
  **Corollary that cost hours**: don't trust "the file content is
  correct and `hyprctl configerrors` shows nothing" as proof a Hyprland
  config change is live — always confirm with `hyprctl getoption` for a
  specific value, and check `ls ~/.config/hypr/` for a `hyprland.lua`
  before assuming `hyprland.conf` is even being read at all.
  **Also**: `~/.config/uwsm/env` is read once at session start, not on
  `hyprctl reload` — a full logout/login is required to test env var
  changes (NVIDIA, fcitx5, cursor), reload only applies for config/*.lua
  keybind/layout/windowrule changes.
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
  launcher, bound to `SUPER+Space` in `config/binds.lua`. **CachyOS's own
  upstream default binds that exact combo to Noctalia's own launcher panel**
  (`noctalia msg panel-toggle launcher`) — our `binds.lua` overrides that
  one line to `vicinae toggle` instead. `SUPER+A` is notifications/control-
  center in the upstream default, not a launcher at all (corrects an
  earlier wrong assumption here). Vicinae is client/server, started as a
  systemd user service (`systemctl --user enable --now vicinae.service`,
  the AUR package ships the unit) rather than an exec-once line — matches
  upstream's own recommendation for uwsm-managed sessions
  (docs.vicinae.com/quickstart/hyprland), and works on the plain
  "Hyprland" session entry too since `autostart.lua` runs
  `dbus-update-activation-environment --systemd --all` on every session
  start either way.
- **Shell**: fish, with fisher as plugin manager (fzf-fish, done plugins).
- **Theme**: Catppuccin Mocha. Default niri/Hyprland focus-ring blue was
  explicitly disliked — use the mauve accent (`#cba6f7`) instead of bright
  blue wherever a border/accent color is configurable.

## Hardware specifics

- **Laptop**: Acer Swift X
- **GPU**: Hybrid/Optimus — Intel or AMD CPU + discrete NVIDIA GPU (RTX
  30/40-series range). Person has had recurring NVIDIA driver problems on
  this machine historically — be extra careful here.
  - Needed env vars (set in `hypr-config/uwsm-env`, deployed to
    `~/.config/uwsm/env` — NOT `hyprland.lua`/`environment.lua`, see the
    Lua-config note above for why): `LIBVA_DRIVER_NAME=nvidia`,
    `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `NVD_BACKEND=direct`,
    `WLR_NO_HARDWARE_CURSORS=1`, `GBM_BACKEND=nvidia-drm`
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
- **Fingerprint sensor**: confirmed (2026-07-25) **EgisTec/LighTuning
  EH575**, USB ID `1c7a:0575`. **Not supported by mainline
  libfprint/fprintd at all** — `fprintd-enroll` reporting "no device" is
  expected behavior on this exact chip, not a setup bug. `setup.sh`
  detects vendor `1c7a` via `lsusb` and skips the fprintd attempt
  entirely rather than failing pointlessly. Community-driver options
  (AUR `open-fprintd-eh575`, or github.com/Animeshz/EgisTec-EH575)
  exist but are unverified/experimental — don't wire them into `setup.sh`
  automatically without the person explicitly deciding to gate sudo/login
  auth on an experimental driver; see NOTES.md #3.
  **Known bug already hit once**: NOTES.md previously said
  `sudo fprintd-enroll` — that enrolls a fingerprint for the *root*
  account, not the user's own login, so nothing the user's session or
  sudo prompt checks against ever matches. Always run plain
  `fprintd-enroll` (no sudo) as the user being enrolled.
- **Power/GPU-switching tooling**: explicitly declined (2026-07-25) despite
  being a hybrid-NVIDIA laptop ahead of international travel — don't
  re-suggest `envycontrol`/`power-profiles-daemon` unless the person
  raises battery life as an actual problem.
- **Keyboard**: physical layout is **French AZERTY** (person is French,
  relocating to Korea). `kb_layout = "fr,us,kr"` in `config/inputs.lua`
  — **fr must be first**, not last: it's the layout active immediately on
  login, and having "us" first (the original bug) meant physically-AZERTY
  keys typed QWERTY until manually toggled. Toggle key is Alt+Shift
  (`kb_options = "grp:alt_shift_toggle"`) — deliberately not Win+Space,
  which collides with Vicinae's launcher toggle on the same combo.

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
- Wants `SUPER+L` bound to lock screen — already upstream default in
  `config/binds.lua`, via `noctalia msg session lock` (the current
  Noctalia CLI IPC syntax; an earlier note here had the older
  `qs -c noctalia-shell ipc call lockScreen lock` form, which was never
  actually verified against a live Noctalia install).
- `SUPER+T` opens the terminal (kitty, per `TERMINAL` in `variables.lua`),
  alongside `SUPER+Return` —
  upstream default binds `SUPER+T` to the EDITOR instead, overridden in
  `config/binds.lua`. Floating toggle is `SUPER+ALT+Space` (upstream
  default, left alone) — `SUPER+V` and `SUPER+T` are both already claimed
  by upstream (clipboard panel, editor) so don't reuse them for anything
  else without checking `config/binds.lua` first.
- Numlock on at startup: `numlock_by_default = true` in
  `config/inputs.lua`.
- **Floating UX gap acknowledged (2026-07-25)**: Hyprland's floating mode is a
  modifier-driven WM convention (SUPER+drag to move), not a Windows/KDE
  clone — no titlebar, no drag-to-edge Snap Assist, ALT+Tab was upstream-bound
  to a bare no-overlay cycle instead of a visual switcher. Addressed:
  - `ALT+Tab` now opens Noctalia's visual window-switcher (upstream had this
    swapped with `SUPER+Tab`, which now does the bare cycle instead).
  - `general.snap.enabled = true` (`windowrules.lua`) — magnetic edge/window
    snapping while dragging. This is NOT Aero Snap (drag-to-edge auto-resize).
  - `SUPER+ALT+Left/Right/Up/Down` — keyboard half/quarter/maximize/restore
    snapping via `resizeactive`/`moveactive exact <w>% <h>%` dispatchers.
    Not `SUPER+Arrow` (that's already directional focus-switching upstream,
    kept as-is) — don't relitigate this collision, it was deliberate.
  - `hyprbars` plugin (official, hyprwm/hyprland-plugins) added for real
    draggable server-side titlebars + close button, installed via `hyprpm`
    in `setup.sh` (guarded — plugin ABI mismatches are a known common
    failure mode, doesn't block the rest of the script if it fails).
    **The `hyprbars` build failed on this machine** (2026-07-25) —
    `hl.plugin.hyprbars` was nil, and the original `windowrules.lua`
    called `.add_button` on it unconditionally, which is a hard Lua
    error that aborted the rest of that file's execution (floating-by-
    default, snap, gaming/dialog rules — all of it, silently). Same bug
    class as the `TERMINAL` crash below: **never call into an optional/
    plugin-provided API without checking it exists first**
    (`if hl.plugin and hl.plugin.hyprbars then ... end`), now guarded.
    Titlebars still don't actually work until `hyprpm enable hyprbars`
    succeeds on that machine — check `/tmp/hyprpm-add.log` for why it
    failed (headers version mismatch is the top suspect).
  - **True drag-to-edge Snap Assist has no Hyprland equivalent, plugin or
    otherwise** — this would require writing compositor-level drag-event
    tooling from scratch. Don't imply it's achievable with a quick config
    tweak if asked again; it isn't.
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
  fisher, fingerprint/PAM wiring, theming, vicinae.service enable
- `hypr-config/inputs.lua` — keyboard layout/options, touchpad, numlock;
  overrides CachyOS upstream `config/inputs.lua`
- `hypr-config/binds.lua` — full copy of CachyOS upstream `config/binds.lua`
  with two lines changed (SUPER+Space -> Vicinae, SUPER+T -> terminal);
  everything else (SUPER+L lock, media keys, workspace binds, etc.) is
  upstream default, not something this repo invented
- `hypr-config/windowrules.lua` — full copy of CachyOS upstream
  `config/windowrules.lua` with one addition: blanket float-by-default
  rule at the top (upstream default is tiling-by-default with per-app
  float exceptions)
- `hypr-config/variables.lua` — full copy of upstream `config/variables.lua`.
  `TERMINAL` was briefly changed to ghostty then reverted back to
  upstream's `kitty` (2026-07-25, person's explicit choice) — `kitty` is
  now in `setup.sh`'s package list alongside `ghostty` (kept installed,
  just not the default). **Never let `TERMINAL` end up undefined** —
  `binds.lua` concatenates it unconditionally on the first launcher bind,
  and a nil value throws a Lua error that silently kills every bind
  declared after it in that file (this exact bug happened once already).
- `hypr-config/uwsm-env` — full copy of upstream `~/.config/uwsm/env` with
  NVIDIA vars uncommented and fcitx5 IM vars added. **`GTK_IM_MODULE` is
  deliberately NOT set** (2026-07-25) — on native Wayland, GTK3/4 talk to
  fcitx5 directly over the Wayland input-method protocol, and setting the
  old X11-style module produces fcitx5's own "Wayland diagnose" warning
  and breaks it. `QT_IM_MODULE`/`XMODIFIERS`/`SDL_IM_MODULE` are still
  set (Qt5/XWayland/SDL2 still need them). Don't re-add `GTK_IM_MODULE`
  without a specific reason.
- `hypridle.conf` — optional auto-lock on idle via Noctalia's lock IPC
  (unaffected by the Lua migration — hypridle is a separate daemon still
  using the classic `.conf` format)
- `config.fish` — aliases, abbreviations, atuin flags, clip function
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
