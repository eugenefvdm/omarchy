# Omarchy workstation journal

## Quick fix: pin static LAN IPs on Arch

If DHCP changed your host IP and your cross-machine setup broke, pin addresses so they stay stable.

Suggested mapping for this lab:

- This machine: `192.168.1.201`
- Remote Intel machine: `192.168.1.202`

### NetworkManager (nmcli) quick steps

```bash
# 1) Find your active connection profile name
nmcli connection show --active

# 2) Set static IPv4 (replace "WiFi" with your profile name)
sudo nmcli connection modify "WiFi" \
  ipv4.method manual \
  ipv4.addresses 192.168.1.201/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "192.168.1.1 1.1.1.1"

# 3) Reconnect that profile
sudo nmcli connection down "WiFi" && sudo nmcli connection up "WiFi"

# 4) Verify
ip -4 addr show | rg '192\.168\.1\.201'
```

Do the same on the other machine with `192.168.1.202/24`.

### LAN Mouse reconfiguration after IP changes

If cursor sharing stops after readdressing, re-register peers:

```bash
# on .201 (this machine)
printf 'connect right 192.168.1.202 4242\nactivate 0\n' | lan-mouse -f cli

# on .202 (remote)
printf 'connect left 192.168.1.201 4242\nactivate 0\n' | lan-mouse -f cli
```

Then confirm both sides are listening and allowed through firewall (`4242/tcp` + `4242/udp`).

A small Laravel application whose main purpose is **living documentation**: notes from building and running **two Omarchy (Arch-based) workstations**, written clearly enough for future you and for anyone browsing the open-source repo on GitHub. The site’s home route serves the welcome page at `/`; over time that page is meant to read like a table-of-contents journal that mirrors this document.

## About this repository

This project is a **Laravel 13** app (Livewire, Flux). It ships with the usual auth and dashboard scaffolding; the emphasis here is the **journal**—commands you ran, what worked, what differed between machines, and short explanations so the story stays searchable and copy-friendly.

## Machines and architecture

| Role | Hardware | Notes |
| --- | --- | --- |
| **Daily / dev** | Apple Mac mini (M2), **AARCH64** | Omarchy on Apple Silicon: same Arch ideas, but **arm64** binaries and occasional packaging or tooling gaps vs common **x86_64** write-ups. |
| **Comparison** | Intel PC, **AMD64 / x86_64** | Side-by-side box for “does this match the blog?” checks—same `pacman` ideas, different architecture when it matters. |

Architecture shows up in real life for **prebuilt binaries**, **containers**, and **third-party tools**. When something differs between hosts, this doc will say so after it has been checked—not assumed.

### Lab network (this repo)

| Host | LAN IP | Role |
| --- | --- | --- |
| This machine | `192.168.1.201` | Where you run this Laravel app and local checks (AARCH64). |
| Remote | `192.168.1.202` | Intel Omarchy box—compare via SSH: `ssh eugene@192.168.1.202` |

IPs are home-LAN; they can change with DHCP unless you reserve them on the router.

To check reachability and SSH into another box on the LAN, see **[Accessing other Omarchies](#accessing-other-omarchies)**. (A probe from the automated assistant’s environment timed out on port 22—verify on your own network.)

## How this documentation grows

1. **Structure**: Top-level **chapters** (like a Google Doc with main headings) and **entries** underneath (subheadings). You add **index topics**; the prose and commands fill in under each.
2. **Sources of truth**: What you describe, plus—when it helps—**localhost** on the AARCH64 machine vs **SSH** on the Intel machine to record **same vs different** behavior.
3. **Audience**: Open source on GitHub; keep assumptions and jargon light enough that others following Omarchy or a similar Arch desktop path can follow along.

## Running the Laravel app

After cloning:

1. `composer install`
2. `cp .env.example .env` then `php artisan key:generate`
3. Ensure the app can write its database file if you use the default **SQLite** setup from `.env.example` (for example `touch database/database.sqlite` if needed), then `php artisan migrate`
4. Front end: `npm install` and `npm run dev`, or use `npm run build` for production assets
5. Alternatively, `composer run dev` may run the common stack together (per your `composer.json` scripts)

For full framework details, see the [Laravel documentation](https://laravel.com/docs).

## Omarchy customization scripts

**Premise:** you **experiment on the Mac** (AARCH64 Omarchy) and capture what works in this journal. **`apply-`** / **`revert-omarchy-customizations.sh`** are **only for fresh Intel (x86_64) rigs**—bring a new install in line with what you’ve settled on, or roll back. **Do not run them on the Mac.** When native Omarchy on ARM64 is a first-class target, you might shift experimentation there; these scripts stay **Intel / stock-default oriented** until you change them.

Minimal SSH helpers (run from any machine that can SSH to the Intel box):

| Script | Purpose |
| --- | --- |
| [`scripts/apply-omarchy-customizations.sh`](scripts/apply-omarchy-customizations.sh) | On the **Intel** host (as your user, over **non-interactive** SSH): Waybar `style.css` **12px → 20px**; **`config.jsonc`**: **`group/tray-expander` → `tray`**, **`tray.icon-size` → 20**; marker file for revert; reload Waybar. **End of run:** prints **`pacman`** lines to run **as root** for **`jq`** + **`pwgen`** (not automated—avoids **`sudo`** / TTY / **fish** issues). |
| [`scripts/revert-omarchy-customizations.sh`](scripts/revert-omarchy-customizations.sh) | Undo apply on the **same** host (user files only). **End of run:** optional **`pacman -Rs pwgen`** as root if you use that workflow. |

```bash
./scripts/apply-omarchy-customizations.sh eugene@192.168.1.202
./scripts/revert-omarchy-customizations.sh eugene@192.168.1.202
```

Requires **SSH keys** (or your usual auth). Extend the scripts as this journal grows.

### SSH, sudo, and root

- **What the wrappers do:** **`ssh user@host bash -s < scripts/remote/…`** — **no** **`-t`** (no pseudo-terminal). That way **bash** on the remote reads the script from stdin; **`ssh -tt`** was sending stdin to **fish** as if you had pasted the script.

- **What needs root on the Intel host:** **`pacman`** only — install **`jq`** (required before **`config.jsonc`** edits can run) and **`pwgen`** per this journal; optional **`pacman -Rs pwgen`** on revert. The remote scripts **do not** call **`sudo`**; they **print** the exact **`pacman`** lines at the end so you can log in, **elevate to root**, and run them yourself.

- **`Waybar` under `~/.config`** is edited as **your user** — no root for **`sed`** / **`jq`** / **`mv`** there.

- **Do not** run the **local** wrapper as **root** (`sudo ./scripts/apply-...`) — that breaks SSH keys and home directory. Use root **on the remote** only for **`pacman`**.

- **If apply says `jq` not found:** install **`jq`** as root, then re-run **`apply`**.

**Troubleshooting (Intel):** If the **reveal chevron** (often **`<`**) is still there, **`modules-right`** still lists **`group/tray-expander`** (apply never ran, or Omarchy overwrote **`config.jsonc`**)—run **`apply`** again. **Small** third-party tray icons next to large system icons are usually **`tray.icon-size`** (stock **12** on Intel vs **20** in this journal); **`apply`** sets **20** to match the Mac.

## Documentation

### Table of contents

- [Quick fix: pin static LAN IPs on Arch](#quick-fix-pin-static-lan-ips-on-arch)
  - [NetworkManager (nmcli) quick steps](#networkmanager-nmcli-quick-steps)
  - [LAN Mouse reconfiguration after IP changes](#lan-mouse-reconfiguration-after-ip-changes)
- [Omarchy customization scripts](#omarchy-customization-scripts)
  - [SSH, sudo, and root](#ssh-sudo-and-root)
- [Lab network](#lab-network-this-repo)
- [Accessing other Omarchies](#accessing-other-omarchies)
- [Firewall](#firewall)
- [Installing programs](#installing-programs)
  - [pwgen](#pwgen)
  - [telegram-desktop](#telegram-desktop)
  - [Slack](#slack)
    - [AUR votes](#aur-votes)
  - [exfatprogs](#exfatprogs)
  - [TablePlus (ARM64 AppImage)](#tableplus-arm64-appimage)
- [Additional programs](#additional-programs)
- [Chromium](#chromium)
  - [New setups: Services, Chromium account, and profiles](#new-setups-services-chromium-account-and-profiles)
  - [Audio troubleshooting (no sound after reboot)](#audio-troubleshooting-no-sound-after-reboot)
- [About application icons in the Waybar](#about-application-icons-in-the-waybar)
- [Waybar tray expander](#waybar-tray-expander)
- [Waybar font size](#waybar-font-size)
- [Lan Mouse](#lan-mouse)
  - [Running the daemon (not just the UI)](#running-the-daemon-not-just-the-ui)
  - [Adding another machine to the right](#adding-another-machine-to-the-right)
- [Idle timers (hypridle)](#idle-timers-hypridle)
  - [DPMS vs screensaver](#dpms-vs-screensaver)
  - [Changing a timer](#changing-a-timer)
- [Notifications: do-not-disturb on a schedule](#notifications-do-not-disturb-on-a-schedule)
  - [Reverting / changing the schedule](#reverting--changing-the-schedule)
- [Notification sounds (mako-sounds)](#notification-sounds-mako-sounds)
  - [Log file location](#log-file-location)
  - [Editing rules](#editing-rules)
  - [Reverting mako-sounds](#reverting-mako-sounds)

### Accessing other Omarchies

Unlike optional tools such as **`pwgen`**, the **SSH server stack is already part of base Omarchy**: the **`openssh`** package (which provides **`sshd`**) is installed out of the box. What you often need is to **run the daemon**—it may be stopped until you start it.

**From this machine** (e.g. `192.168.1.201`), toward the other host (e.g. `192.168.1.202`):

```bash
ping -c1 192.168.1.202
ssh -v eugene@192.168.1.202
```

- `ping` confirms basic L3 reachability on your network.
- `ssh -v` prints verbose handshake detail; if **connection refused** or **timed out** before authentication, the **sshd service** may be stopped, or a **firewall** may be blocking TCP **22** (see **[Firewall](#firewall)**).

**On the machine you are logging *into*** (the “server” side), start the SSH server:

```bash
sudo systemctl start sshd
```

That runs **`sshd`** now. To also start it on every boot:

```bash
sudo systemctl enable --now sshd.service
```

If `openssh` were ever missing (unusual on Omarchy), install it with `sudo pacman -S openssh`—the package name is **`openssh`**, not `sshd-server`.

Then retry `ssh eugene@192.168.1.202` from `192.168.1.201`. If **`sshd` is active** but SSH from the LAN still hangs or times out, open **TCP 22** on the server’s host firewall—see **[Firewall](#firewall)**.

### Firewall

On the **Intel remote** host (`192.168.1.202`), **`ufw` is active**. Inbound **SSH (TCP 22)** was not in the allow list below, so LAN clients could reach the IP but not complete SSH until port **22** is allowed.

**`sudo ufw status` snapshot** (default rules before opening SSH—recorded on that machine):

| To | Action | From | Notes |
| --- | --- | --- | --- |
| `53317/udp` | ALLOW | Anywhere | |
| `53317/tcp` | ALLOW | Anywhere | |
| `172.17.0.1:53/udp` | ALLOW | `172.16.0.0/12` | Docker DNS (`allow-docker-dns`) |
| `4242/udp` | ALLOW | Anywhere | |
| `4242/tcp` | ALLOW | Anywhere | |
| `53317/udp` | ALLOW | Anywhere (IPv6) | |
| `53317/tcp` | ALLOW | Anywhere (IPv6) | |
| `4242/udp` | ALLOW | Anywhere (IPv6) | |
| `4242/tcp` | ALLOW | Anywhere (IPv6) | |

**Allow SSH (TCP 22)** on the machine acting as the SSH server:

```bash
sudo ufw allow 22/tcp
```

Then confirm with `sudo ufw status` (you should see `22/tcp ALLOW Anywhere` and the IPv6 counterpart if applicable).

If something else still blocks access, also confirm your **router** is not filtering LAN-to-LAN traffic (uncommon on home networks).

### Installing programs

On Arch/Omarchy, see whether a **package** is already installed:

```bash
pacman -Q <pkgname>
```

Installed → prints the name and version, exit **0**. Missing → *was not found* and exit **non-zero**. On `PATH`: `command -v <name>`.

Remote check (SSH keys to `eugene@192.168.1.202`):

```bash
ssh eugene@192.168.1.202 'pacman -Q <pkgname>'
```

Installing through the **Omarchy “Install” UI** is still **`pacman`** for official repo packages—same names and result as the terminal. **AUR** installs (when you use an AUR helper or a UI that targets the AUR) usually **build** the package on your machine or run upstream install scripts—slower, needs build tools, and you should trust the `PKGBUILD`.

#### pwgen

**[pwgen](https://linux.die.net/man/1/pwgen)** prints random passwords or passphrases in the terminal—useful for disposable secrets, test fixtures, or one-off strings without leaving the shell.

**Install** (any Omarchy host, local shell):

```bash
sudo pacman -S pwgen
```

**Intel `192.168.1.202` over SSH:** `sudo` needs a password; use a TTY so the prompt works:

```bash
ssh -t eugene@192.168.1.202 'sudo pacman -S pwgen'
```

(Automated non-interactive install from this journal is skipped—remote `sudo` is not passwordless.)

**Status in this journal**

| Host | `pacman -Q pwgen` |
| --- | --- |
| `192.168.1.201` | `pwgen 2.08-3` |
| `192.168.1.202` | not installed until you run the `ssh -t …` install above; then re-check with `ssh eugene@192.168.1.202 'pacman -Q pwgen'`. |

#### telegram-desktop

**Omarchy menu install:** **Super** + **Shift** + **Space** (Omarchy menu) → type **`inst`** → open **Install** → type **`telegram-desktop`** → run the install. You will be prompted for your **password**.

#### Slack

Slack does not ship in the main **Arch repos**; “native” on Linux is usually the **Electron** desktop app. Options:

- **AUR** — e.g. **`slack-desktop`** (repackages Slack’s official build). Install with your AUR helper (`yay -S slack-desktop`, etc.) if you use one; see [AUR](https://aur.archlinux.org/packages?O=0&K=slack).
- **Flatpak** — **`com.slack.Slack`** from [Flathub](https://flathub.org/apps/com.slack.Slack): separate from `pacman`, but a normal desktop window (`flatpak install flathub com.slack.Slack`).
- **Web** — [Slack in the browser](https://app.slack.com) or a Chromium **Install app** / PWA; no local Slack package.

##### AUR votes

Each package on the [AUR](https://aur.archlinux.org/) shows a **vote** total (from logged-in accounts). More votes usually mean wider use and more eyes on the `PKGBUILD`—not a proof of safety, but a useful tie-breaker when several packages do the same job (including Slack variants).

**Example (as of this writing):** **`slack-desktop`** ~**630** votes vs **`slack-desktop-wayland`** ~**16**. Open both package pages and compare votes, last update, and comments before you install.

#### exfatprogs

**[`exfatprogs`](https://github.com/exfatprogs/exfatprogs)** is the Samsung-maintained userland for the **exFAT** filesystem on Linux: `mkfs.exfat` to format, `fsck.exfat` to check / repair, plus `tune.exfat`, `dump.exfat`, `exfatlabel`. Linux can already **read / write** exFAT in-kernel since 5.4, but you need this package to **create** an exFAT volume or check one.

**Why exFAT?** It's the practical filesystem for USB sticks, SD cards, and external drives that need to be **read and written natively on Linux, Windows, and macOS** — no extra drivers anywhere:

| OS | exFAT support |
| --- | --- |
| **Linux** | Kernel ≥ 5.4 (read/write); `exfatprogs` for `mkfs` / `fsck`. |
| **Windows** | Built in since Vista SP1. |
| **macOS** | Built in since 10.6.5. |

Versus the alternatives: **FAT32** caps single files at **4 GiB**; **NTFS** is awkward on macOS (read-only without third-party drivers); **APFS / HFS+** aren't supported on Windows; **ext4** isn't supported on Windows or macOS.

**Install** (any Omarchy host, local shell):

```bash
sudo pacman -S exfatprogs
```

**Common commands:**

```bash
sudo mkfs.exfat -L MYDISK /dev/sdX1   # format partition as exFAT with label MYDISK
sudo fsck.exfat /dev/sdX1             # check / repair
exfatlabel /dev/sdX1                  # read or set the volume label
```

(Identify `/dev/sdX1` first with `lsblk` — getting the device wrong destroys data.)

**Status in this journal**

| Host | `pacman -Q exfatprogs` |
| --- | --- |
| `192.168.1.201` | `exfatprogs 1.3.2-1` |
| `192.168.1.202` | `exfatprogs 1.3.2-1` |

#### TablePlus (ARM64 AppImage)

TablePlus provides a Linux ARM64 AppImage build, which fits this AARCH64 setup.

Reference download page: [TablePlus Linux Installation](https://tableplus.com/download/linux).

Install (user-local, no system package changes):

```bash
mkdir -p ~/Apps/TablePlus
cd ~/Apps/TablePlus
curl -fL -o TablePlus-aarch64.AppImage \
  https://tableplus.com/release/linux/arm64/TablePlus-aarch64.AppImage
chmod +x TablePlus-aarch64.AppImage
```

Run:

```bash
~/Apps/TablePlus/TablePlus-aarch64.AppImage
```

Status in this journal: **confirmed launching successfully on-screen** on this machine.

### Additional programs

Index of optional **pacman** packages we care about; install/check steps live under **[Installing programs](#installing-programs)**.

- **[pwgen](#pwgen)** — password generator CLI.
- **[telegram-desktop](#telegram-desktop)** — Telegram client (`telegram-desktop`).
- **[Slack](#slack)** — not in core repos; AUR / Flatpak / web.
- **[exfatprogs](#exfatprogs)** — exFAT userland (`mkfs.exfat`, `fsck.exfat`); cross-platform USB / SD card filesystem.
- **[TablePlus (ARM64 AppImage)](#tableplus-arm64-appimage)** — GUI DB client via upstream ARM64 AppImage.

### Chromium

#### New setups: Services, Chromium account, and profiles

On a **fresh** Omarchy machine, work through **Services** in the Omarchy flow (e.g. **Super** + **Shift** + **Space** → **Install** / onboarding) and install **Chromium Account**—the piece that wires Chromium to **Google account** sign-in and related behaviour. Do that **before** you rely on multiple browser identities.

After **Chromium Account** is installed, open Chromium and use the **profile** menu to **Add** extra **Chromium profiles** (work, personal, client, …). Extensions (including **1Password** in the next paragraph) are **per profile**, so separate profiles keep logins and extensions apart.

**Remember:** install the **[1Password](https://chromewebstore.google.com/detail/1password/aeblfdkhhhdcdjpifhhbdiojplfjncoa)** extension in **Chromium** (Chrome Web Store; Chromium supports the same extension). The store may warn that you should use **Chrome**—you can **ignore that** for Chromium.

#### Audio troubleshooting (no sound after reboot)

If YouTube/Chromium is playing but you hear nothing, this quick flow restores routing on Omarchy (PipeWire/WirePlumber):

1. Restart the user audio stack:

```bash
systemctl --user restart wireplumber pipewire pipewire-pulse
```

2. Inspect current sink IDs and Chromium stream IDs:

```bash
wpctl status
pactl list short sink-inputs
```

3. Route Chromium to the target sink and unmute both sink + stream.

Soundcore example (replace IDs as needed):

```bash
wpctl set-default 102
wpctl set-mute 102 0
wpctl set-volume 102 1.0
pactl move-sink-input 87 102
pactl set-sink-input-mute 87 0
pactl set-sink-input-volume 87 100%
```

Jabra example:

```bash
wpctl set-default 60
wpctl set-mute 60 0
wpctl set-volume 60 1.0
pactl move-sink-input 87 60
pactl set-sink-input-mute 87 0
pactl set-sink-input-volume 87 100%
```

4. If Bluetooth sink disappears, restart bluetooth and reconnect:

```bash
sudo systemctl restart bluetooth
bluetoothctl connect 3C:39:E7:B7:54:84
```

Notes:
- In `wpctl status`, `*` marks the current default sink.
- Chromium may stay attached to an old route until `pactl move-sink-input` is run.
- If `Settings -> Default Configured Devices` references an old `bluez_output...`, set a fresh default with `wpctl set-default <sink-id>`.

Single-command helper (from this repo):

```bash
./scripts/audio-route.sh soundcore
./scripts/audio-route.sh jabra
```

Optional: add `--restart-audio` to restart WirePlumber/PipeWire first.

### About application icons in the Waybar

**Waybar** is a **status bar** for **Wayland** sessions (Omarchy’s desktop uses it with the compositor—clock, workspaces, tray area, and similar widgets along the edge of the screen).

**Telegram** and **1Password** register **tray / status icons** that show up in Waybar once those apps are running. By default those icons sit in a **collapsed** tray: press **<** to expand it and reveal them—unless you remove the expander (next section).

### Waybar tray expander

Omarchy’s default **`~/.config/waybar/config.jsonc`** lists **`group/tray-expander`** in **`modules-right`**. That group combines **`custom/expand-icon`** (the **chevron** / reveal control) and **`tray`** in a drawer—the reveal control (often shown as **<**).

**This journal:** drop the drawer and show tray icons all the time by putting **`"tray"`** in **`modules-right`** instead of **`"group/tray-expander"`** (one string swap in that array). Unused `group/tray-expander` / `custom/expand-icon` blocks can stay in the file; Waybar only instantiates what **`modules-right`** references.

**Tray icon size:** the **`tray`** module in **`config.jsonc`** has **`icon-size`** (stock Intel is often **12**). That controls **StatusNotifier** / app tray glyphs (Telegram, Slack, …). This journal uses **20** so those icons **match the bar scale** and the Mac. **`style.css` `font-size`** does **not** resize tray pixmaps—change **`tray.icon-size`** for that.

**Tooling:** `jq` edits JSON safely (`pacman -S jq`). The apply script writes **`~/.config/waybar/.omarchy-tray-expand-removed`**: **line 1** = **`group/tray-expander`** index in **`modules-right`**, or **`-1`** if it was already absent; **line 2** = **`tray.icon-size` before apply** (for revert). Revert restores the expander slot when line 1 is a **non-negative** index, then restores **`tray.icon-size`** from line 2. The install scripts are **Intel-only**—see [Omarchy customization scripts](#omarchy-customization-scripts).

### Waybar font size

While switching between the **Mac mini (AARCH64)** and the **Intel** Omarchy box, the **Waybar text was enlarged** for readability (exact sizes differ per machine/DPI).

**Where to change it:** `~/.config/waybar/` — most often **`style.css`** (`font-size` on the bar and modules); sometimes **`config`** if fonts are set there. Override Omarchy’s defaults in that directory on each host if you want the same look on both.

**`~/.config/waybar/style.css` compared** (`diff` first file = **`192.168.1.201`**, second = **`192.168.1.202`**):

| | **`192.168.1.201` (Mac, AARCH64)** | **`192.168.1.202` (Intel)** |
| --- | --- | --- |
| `*` rule `font-size` | **20px** | **12px** |
| Extra blocks (only on Mac) | `#custom-nightlight`, `#custom-claude`, `#custom-slack`, `#custom-fractal` | — |

Reproduce:

```bash
diff -u ~/.config/waybar/style.css <(ssh eugene@192.168.1.202 'cat ~/.config/waybar/style.css')
```

Unified diff (as captured, 2026-04-19):

```diff
--- style.css (192.168.1.201)
+++ style.css (192.168.1.202)
@@ -8,7 +8,7 @@
   border-radius: 0;
   min-height: 0;
   font-family: 'JetBrainsMono Nerd Font';
-  font-size: 20px;
+  font-size: 12px;
 }
 
 .modules-left {
@@ -81,19 +81,6 @@
   padding-bottom: 1px;
 }
 
-#custom-nightlight {
-  min-width: 10px;
-  margin: 0 18px 0 0;
-}
-
-#custom-nightlight.night {
-  color: #e8a84a;
-}
-
-#custom-nightlight.day {
-  opacity: 0.5;
-}
-
 #custom-screenrecording-indicator.active {
   color: #a55555;
 }
@@ -111,30 +98,3 @@
 #custom-voxtype.recording {
   color: #a55555;
 }
-
-#custom-claude {
-  min-width: 10px;
-  margin: 0 18px 0 0;
-}
-
-#custom-claude.inactive {
-  opacity: 0.35;
-}
-
-#custom-slack {
-  min-width: 10px;
-  margin: 0 18px 0 0;
-}
-
-#custom-slack.inactive {
-  opacity: 0.35;
-}
-
-#custom-fractal {
-  min-width: 10px;
-  margin: 0 18px 0 0;
-}
-
-#custom-fractal.inactive {
-  opacity: 0.35;
-}
```

### Lan Mouse

[**Lan Mouse**](https://github.com/feschber/lan-mouse) shares one keyboard and mouse across machines on the LAN: move the cursor off an edge of one screen and it appears on the next. The default transport is **UDP/TCP 4242** (already opened in [Firewall](#firewall) on the Intel host). Version installed here: `lan-mouse 0.10.0`.

**Current setup** (Mac `.112` on the **left**, Intel `.125` on the **right**):

| Host | Live client in the daemon | Meaning |
| --- | --- | --- |
| **`192.168.1.201`** (Mac, this machine) | `client 0: 192.168.1.202:4242 (right), active: true` | Pushing the cursor off the **right** edge here lands on `.202`. |
| **`192.168.1.202`** (Intel) | `client ?: 192.168.1.201:4242 (left), active: true` | Pushing the cursor off the **left** edge there returns to `.201`. |

The two sides are **mirror images**: each host names the other as a neighbour and gives the **edge of its own screen** that crosses to it.

> ⚠️ **Lan Mouse 0.10.x gotcha — `config.toml` clients are *not* live clients.**
> `~/.config/lan-mouse/config.toml` stores **global settings** (port, release bind, etc.). The `[client.*]` blocks look like neighbour definitions, but the **v0.10.0 daemon does not register them as live peers** — the CLI REPL confirms this (`no such client: 0` on a fresh daemon, even with the TOML in place). Neighbours must be registered **via the `connect` command (CLI or GUI "Add client") while the daemon is running**. Losing this leaves the daemon up, UDP `4242` listening, and the cursor stuck at the edge with no crossing and no error. This journal keeps `[client.right]` in `config.toml` as documentation only; the actual wiring is done by `ExecStartPost=` in `lan-mouse.service` — see next section.

#### Running the daemon (not just the UI)

**Trap 1:** launching `lan-mouse` with no arguments starts **GTK frontend + daemon in the same process**. Close the window and the daemon dies — cursor crossing stops and nothing is listening on UDP `4242` anymore.

**Trap 2:** even with the daemon running, **no neighbour is loaded from `config.toml`** on v0.10.0 (see gotcha above). Every time the daemon (re)starts, the client list is empty until something calls `connect …` / `activate 0` on the CLI socket or you click "Add client" in the GUI.

On Omarchy there is **no packaged `lan-mouse.service`** (`pacman -Qlq lan-mouse` only ships `de.feschber.LanMouse.desktop`), so both traps are solved together with one user unit plus a small post-start helper.

**The helper** — re-registers the neighbour on every daemon start:

```bash
# ~/.local/bin/lan-mouse-apply-clients
#!/usr/bin/env bash
# Populate and activate lan-mouse clients in the running daemon.
# In lan-mouse 0.10.x the TOML [client.*] sections are NOT auto-loaded as live
# clients; the CLI/GUI "connect" path is. This script runs as ExecStartPost=.
set -euo pipefail

# Give the daemon a moment to finish initialising its control socket.
sleep 2

printf 'connect right 192.168.1.202 4242\nactivate 0\n' \
  | /usr/bin/lan-mouse -f cli >/dev/null 2>&1 || true
```

```bash
chmod +x ~/.local/bin/lan-mouse-apply-clients
```

The CLI REPL speaks to the already-running daemon over its control socket. Known commands (from `help`): `connect left|right|top|bottom <host> [<port>]`, `disconnect <id>`, `activate <id>`, `deactivate <id>`, `set-host <id> <host>`, `set-port <id> <host>`.

**The service** — starts the daemon, then applies clients:

```ini
# ~/.config/systemd/user/lan-mouse.service
[Unit]
Description=Lan Mouse daemon (capture + forward to peers defined in ~/.config/lan-mouse/config.toml)
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/lan-mouse --daemon
ExecStartPost=%h/.local/bin/lan-mouse-apply-clients
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
```

Enable and start:

```bash
systemctl --user daemon-reload
systemctl --user enable --now lan-mouse.service
```

**Verify** (four things that must all be true):

```bash
systemctl --user status lan-mouse             # active (running), ExecStartPost exited 0/SUCCESS
ss -tulpn | grep ':4242'                      # UDP 4242 owned by lan-mouse
journalctl --user -u lan-mouse -n 20          # look for the backends + release bind
printf '' | timeout 3 lan-mouse -f cli 2>&1 | grep '^client '
# expected: client 0: 192.168.1.202:4242 (right), ips: [] active: true, dns: {192.168.1.202}
```

A healthy startup log shows:

- `using config: "/home/eugene/.config/lan-mouse/config.toml"` — right file being read (for globals; see gotcha).
- `using emulation backend: wlroots` — standard on Hyprland.
- `using capture backend: layer-shell` — Hyprland does not (yet) implement `org.freedesktop.portal.InputCapture`, so `lan-mouse` falls back from `input-capture-portal` to `layer-shell`. That `WARN input-capture-portal … unavailable` line is **expected on Hyprland and harmless**.
- `release bind: [KeyLeftCtrl, KeyLeftShift, KeyLeftMeta, KeyLeftAlt]` — after the cursor crosses, **press `Ctrl + Shift + Super + Alt`** to pull it back.

**Troubleshooting (copy-pasteable):**

| Symptom | Check | Fix |
| --- | --- | --- |
| Cursor does not cross off the right edge | `ps -ef \| grep lan-mouse` on **this** host | Start the daemon: `systemctl --user start lan-mouse`. Without it there is no capture side. |
| Daemon is up but still nothing crosses | `printf '' \| timeout 3 lan-mouse -f cli \| grep '^client '` | If empty or `active: false` → `ExecStartPost` didn't run. Run `~/.local/bin/lan-mouse-apply-clients` manually, or `systemctl --user restart lan-mouse`. |
| This side OK, cursor arrives but remote ignores it | On the remote: `ss -tulpn \| grep 4242` and `sudo ufw status` | Start `lan-mouse --daemon` on the remote, register **this** host there (`connect left 192.168.1.201 4242` → `activate 0`), and confirm 4242/tcp + 4242/udp open (already open on `.202`). |
| Closing the GUI kills crossing | `systemctl --user status lan-mouse` | GUI and daemon are the **same** process if you run plain `lan-mouse`. Use the service above, then use the GUI only for tweaks. |
| Moving the mouse around does nothing even with service active | `journalctl --user -u lan-mouse -f` while you move | If you see `input-capture-portal … unavailable` **and nothing else**, fall-back backend didn't load — try `--capture-backend layer-shell` or `--capture-backend x11` in `ExecStart=`. |

**Revert:**

```bash
systemctl --user disable --now lan-mouse.service
rm ~/.config/systemd/user/lan-mouse.service ~/.local/bin/lan-mouse-apply-clients
systemctl --user daemon-reload
```

#### Adding another machine to the right

Lan Mouse lets a host hold **one neighbour per edge** (`left`, `right`, `top`, `bottom`) — `.112` already uses **`right`** for `.125`. To extend the chain so a **third** Omarchy box (call it `192.168.1.130`) sits **further right**, register it on the **right edge of `.125`** (and mirror `.125` on the new host's left). The cursor then travels `.112` → `.125` → `.130` and back.

Remember (previous section): on v0.10.x the TOML is documentation, the **live client list comes from `connect` + `activate`**. Keep the TOML in sync for readability *and* encode the same calls in each box's `lan-mouse-apply-clients` helper.

**1. On `192.168.1.202`** — `.202` already has `.201` wired on its **left**; add `.130` as a **second** client on the **right**:

```toml
# ~/.config/lan-mouse/config.toml  (documentation only; globals live at the top of the file)
[client.left]
  hostname = "192.168.1.201"
  port = 4242
  pos = "left"

[client.right]
  hostname = "192.168.1.130"
  port = 4242
  pos = "right"
```

```bash
# ~/.local/bin/lan-mouse-apply-clients on .125
printf 'connect left 192.168.1.201 4242\nactivate 0\nconnect right 192.168.1.130 4242\nactivate 1\n' \
  | /usr/bin/lan-mouse -f cli >/dev/null 2>&1 || true
```

(Clients get sequential IDs as they're `connect`-ed — `0` for the first line, `1` for the second. `activate <id>` flips each one on.)

**2. On `192.168.1.130`** (the new host) — install Lan Mouse, open the port, install the service + helper (same as [Running the daemon](#running-the-daemon-not-just-the-ui)), and wire `.125` as the **left** neighbour:

```toml
# ~/.config/lan-mouse/config.toml
[client.left]
  hostname = "192.168.1.202"
  port = 4242
  pos = "left"
```

```bash
# ~/.local/bin/lan-mouse-apply-clients on .130
printf 'connect left 192.168.1.202 4242\nactivate 0\n' \
  | /usr/bin/lan-mouse -f cli >/dev/null 2>&1 || true
```

```bash
sudo ufw allow 4242/tcp
sudo ufw allow 4242/udp
```

**3. Apply** by restarting the service on both boxes (`systemctl --user restart lan-mouse`). Confirm with the live-state check: `printf '' | lan-mouse -f cli | grep '^client '` should show each expected neighbour `active: true`. Test by sliding off the right edge of `.125` (→ `.130`), off the left of `.130` (→ `.125`), then off the left of `.125` (→ `.112`).

**Notes**

- Hostnames can be **IPs** (as above) or DNS names; IPs are simplest on a home LAN and survive `mDNS` quirks.
- `pos` on the CLI is the edge **on the host you're editing**, not on the neighbour. Mismatched edges (both sides claim `"right"`) will not connect cleanly.
- To put the new machine **directly to the right of `.112`** instead of chaining, you'd have to **replace** `.112`'s existing right client (it's the only `right` slot): change the line in `~/.local/bin/lan-mouse-apply-clients` here to point at `.130` and restart the service. Chaining via `.125` is the natural way to extend the current setup without disturbing it.

### Idle timers (hypridle)

Omarchy runs **[`hypridle`](https://wiki.hypr.land/Hypr-Ecosystem/hypridle/)** to react to **idle time** (no keyboard / pointer input). Config: **`~/.config/hypr/hypridle.conf`**; started from **`~/.config/hypr/autostart.conf`**. Each `listener { … }` block has a `timeout` in **seconds** and an `on-timeout` command; timers count from the **last input**.

**See current timers:**

```bash
grep -nE 'timeout|on-timeout' ~/.config/hypr/hypridle.conf
```

**Listeners on this machine** (matches stock Omarchy after the experiment below was reverted):

| Purpose | `on-timeout` | Value |
| --- | --- | --- |
| **Screen power off (DPMS)** | `hyprctl dispatch dpms off` | `330` s (**5.5 min**) |
| Keyboard backlight off ×2 | `brightnessctl … kbd_backlight … set 0` | `330` s (5.5 min) |
| **Screensaver** | `pidof hyprlock \|\| omarchy-launch-screensaver` | `900` s (**15 min**) |
| Lock session (commented out) | `loginctl lock-session` | `300` s — disabled in this journal |

#### DPMS vs screensaver

These are **two different things**:

- **DPMS** (*Display Power Management Signaling*) is a **hardware** power command the compositor sends to the monitor: `hyprctl dispatch dpms off` puts the panel to sleep (backlight off, electronics idle). Nothing is drawn — the screen is physically dark.
- **Omarchy's screensaver** is a **userland program** — `omarchy-launch-screensaver` opens a fullscreen terminal (`Alacritty` / `Ghostty` / `Kitty`) running `omarchy-cmd-screensaver` (a `tte` text-effects animation), window class `org.omarchy.screensaver`. It draws pixels; it does **not** touch monitor power.

With stock ordering (**DPMS 5.5 min, screensaver 15 min**) the monitor goes dark first; the screensaver later fires into an off panel so you never see it in everyday use. On wake (`dpms on`) the panel comes back and any running screensaver is visible for a moment before input dismisses it. This is why "leave the box for a while, come back, screen is off" works — DPMS is what you actually feel.

**Gotcha — do not invert the order.** On this host, making the screensaver fire **before** DPMS (e.g. screensaver at 60 s, DPMS at 120 s) caused DPMS to never fire at all: verbose `hypridle -v` showed the screensaver rule idled and ran `omarchy-launch-screensaver`, but no `Idled` event ever arrived for the DPMS rule — the screensaver's fullscreen activation appears to prevent `ext_idle_notifier_v1` from reporting the later idle threshold. Keep DPMS short and screensaver long (or just leave stock).

#### Changing a timer

Workflow — backup, **context-aware edit** (so the three identical `timeout = 330` blocks aren't all changed), restart `hypridle`.

**1. Backup and edit.** Use a marker phrase from the listener's `on-timeout` to target the right block. Examples:

```bash
cp ~/.config/hypr/hypridle.conf \
   ~/.config/hypr/hypridle.conf.bak.$(date +%Y%m%d-%H%M%S)

sed -i -E '/timeout = 900/{N
/omarchy-launch-screensaver/s/timeout = 900/timeout = <NEW>/
}' ~/.config/hypr/hypridle.conf

sed -i -E '/timeout = 330/{N
/hyprctl dispatch dpms off/s/timeout = 330/timeout = <NEW>/
}' ~/.config/hypr/hypridle.conf
```

The `N` appends the next line into `sed`'s pattern space so the substitution only fires when `timeout = X` is immediately followed by the marker `on-timeout` — the `kbd_backlight` blocks (same `330`) are left untouched.

**2. Restart `hypridle` inside the Hyprland session** (so it inherits `WAYLAND_DISPLAY` / `HYPRLAND_INSTANCE_SIGNATURE`):

```bash
pkill hypridle && sleep 1 && hyprctl dispatch exec hypridle
pgrep -a hypridle
```

**3. Verify** and test with `date; sleep <NEW+5>; date` while not touching input.

**Revert to the latest backup (any time):**

```bash
LATEST=$(ls -1t ~/.config/hypr/hypridle.conf.bak.* | head -1)
cp "$LATEST" ~/.config/hypr/hypridle.conf
pkill hypridle && sleep 1 && hyprctl dispatch exec hypridle
grep -nE 'timeout|on-timeout' ~/.config/hypr/hypridle.conf
```

**Debugging tip.** Run `hypridle -v` to a log file and watch for `Idled: rule <id>` / `Resumed: rule <id>` lines — a missing `Idled` for a rule means the compositor never told that listener to fire (most often an ordering / activity issue like the one above):

```bash
pkill hypridle && sleep 1
hyprctl dispatch exec -- sh -c 'exec hypridle -v >/tmp/hypridle.log 2>&1'
tail -f /tmp/hypridle.log
```

### Notifications: do-not-disturb on a schedule

**Goal:** silence notifications and mute the browser **17:00 → 08:00 weekdays + all weekend**, then re-enable both **08:00 weekdays**. Manual override via a Waybar moon icon and a Hyprland keybind. Calendar exception **skipped** — see below.

**Components used / built**

| Piece | What it does | Where |
| --- | --- | --- |
| **`mako`** | Wayland notification daemon. Already ships a `[mode=do-not-disturb] invisible=true` block in `~/.local/share/omarchy/default/mako/core.ini`, with a clever `notify-send` exception so toggle-confirmation toasts still pop. | Stock Omarchy. |
| **`custom/notification-silencing-indicator`** | Moon icon already in your Waybar centre; `on-click` runs `omarchy-toggle-notification-silencing`. | Stock Omarchy. |
| **Moon icon font-size override** *(new)* | Pulled `#custom-notification-silencing-indicator` out of the grouped `font-size: 10px` indicator rule and gave it its own block at **`font-size: 20px`** (`min-width: 20px`, `margin-left: 8px`) so the moon matches the bar's native `*` font-size and the right-side custom icons (see [Waybar font size](#waybar-font-size)). Waybar live-reloads CSS (`reload_style_on_change: true`), no restart needed. | `~/.config/waybar/style.css` (backup at `style.css.bak.<timestamp>`) |
| **`omarchy-dnd`** *(new)* | Wrapper around `makoctl mode -a/-r do-not-disturb` that **also** mutes / unmutes Chromium-family sink-inputs via `pactl`, refreshes Waybar (`pkill -RTMIN+10 waybar`), and pings `notify-send`. Subcommands `on` / `off` / `toggle` / `status`; idempotent. | `~/.local/bin/omarchy-dnd` |
| **`omarchy-dnd-on.{service,timer}`** *(new)* | `OnCalendar=Mon..Fri *-*-* 17:00:00`, `Persistent=true`. Calls `omarchy-dnd on`. | `~/.config/systemd/user/` |
| **`omarchy-dnd-off.{service,timer}`** *(new)* | `OnCalendar=Mon..Fri *-*-* 08:00:00`, `Persistent=true`. Calls `omarchy-dnd off`. | `~/.config/systemd/user/` |
| Hyprland keybind *(new)* | `bindd = SUPER ALT, N, Toggle DND, exec, ~/.local/bin/omarchy-dnd toggle` | `~/.config/hypr/bindings.conf` |

**Why only two timers cover seven days.** Friday 17:00 turns DND on. The next "off" timer doesn't fire until Monday 08:00. Saturday and Sunday are silent for free. `Persistent=true` means a reboot during off-hours still leaves you in DND on the next start.

**Browser audio mute — what's covered.** When DND turns **on**, `omarchy-dnd` walks `pactl list sink-inputs` and mutes any whose `application.process.binary` is `chromium` / `chrome` / `brave` / `firefox`. When DND turns **off**, those streams are unmuted. **Limitation:** new browser streams that *start while DND is on* are not auto-muted — Chromium typically reuses a single audio process across tabs, so once muted it usually stays muted, but a freshly launched browser would not be. Good enough for "I walked away at 17:00 with YouTube playing"; not a hard guarantee.

**Calendar exception skipped.** `omarchy-launch-webapp` runs Chromium PWAs as `chromium --app=URL`, so **every Chromium PWA notification arrives in mako with the same `App name: Chromium`** — calendar reminders, monitoring alerts, mail, etc. all indistinguishable. A clean `[mode=do-not-disturb app-name=Calendar] invisible=false` rule is therefore not possible without moving the calendar to a non-Chromium app (e.g. `gnome-calendar`, Thunderbird) that registers its own desktop entry. Future journal entry if it bites.

**Manual control** (any time):

| Action | How |
| --- | --- |
| **Toggle** DND | Click the moon icon in Waybar **or** press **`SUPER + ALT + N`** **or** run `omarchy-dnd toggle`. |
| Force on / off | `omarchy-dnd on` / `omarchy-dnd off`. |
| Read state | `omarchy-dnd status` (prints `on` / `off`). |
| See next scheduled run | `systemctl --user list-timers omarchy-dnd-*` |
| Watch what fires | `journalctl --user -u omarchy-dnd-on -u omarchy-dnd-off -f` |

#### Reverting / changing the schedule

**Change the times** — edit the `OnCalendar=` lines and reload. `OnCalendar` accepts `systemd.time(7)` syntax (e.g. `Mon..Fri *-*-* 18:30:00`):

```bash
sed -i 's/17:00:00/18:30:00/' ~/.config/systemd/user/omarchy-dnd-on.timer
systemctl --user daemon-reload && systemctl --user restart omarchy-dnd-on.timer
systemctl --user list-timers omarchy-dnd-*
```

**Disable temporarily** (timers off, manual control still works):

```bash
systemctl --user disable --now omarchy-dnd-on.timer omarchy-dnd-off.timer
```

**Full revert** — remove every file we added, drop the keybind, reload Hyprland:

```bash
systemctl --user disable --now omarchy-dnd-on.timer omarchy-dnd-off.timer
rm ~/.config/systemd/user/omarchy-dnd-{on,off}.{service,timer}
systemctl --user daemon-reload
rm ~/.local/bin/omarchy-dnd
sed -i '/omarchy-dnd toggle/,+0d; /Toggle Omarchy do-not-disturb/d' \
    ~/.config/hypr/bindings.conf
hyprctl reload
makoctl mode -r do-not-disturb 2>/dev/null || true
```

### Notification sounds (mako-sounds)

`mako` itself does not play a per-notification sound — it just surfaces the toast. To get distinct sounds for specific apps and message patterns (Slack channel X, PRTG alerts, Claude replies, etc.) this journal runs a small background daemon, **`mako-sounds`**, that polls `makoctl history` and plays a `.oga` via `pw-play` whenever a new notification appears.

**Pieces**

| Piece | Path |
| --- | --- |
| Script | `~/.local/bin/mako-sounds.sh` |
| systemd unit | `~/.config/systemd/user/mako-sounds.service` (auto-restart on failure, starts with `graphical-session.target`) |
| **Log file** | **`~/.local/state/mako-sounds/mako-sounds.log`** — see [below](#log-file-location) |
| Seen-ID state | `~/.local/state/mako-sounds/seen` |
| Sound assets | `~/.local/share/sounds/*.oga` |

**Rule priority (three tiers, checked per notification):**

1. **`CONTENT_SOUNDS`** — substring match on the notification **message**. Highest priority; this is where Slack channel–specific sounds and "silent" suppressions live (e.g. `"New message in #orders" → coin.oga`).
2. **`APP_SOUNDS`** — exact match on **App name** from `makoctl` (e.g. `notify-send`, `Chromium`). Fallback when no content rule hits.
3. **`DEFAULT_SOUND`** — final fallback (currently `default.oga`).

**Common commands**

```bash
systemctl --user status mako-sounds            # running? last start?
journalctl --user -u mako-sounds -f            # systemd journal stream
tail -f ~/.local/state/mako-sounds/mako-sounds.log   # per-notification file log
systemctl --user restart mako-sounds           # pick up edits to the script
```

#### Log file location

**`~/.local/state/mako-sounds/mako-sounds.log`** (standardised under `$XDG_STATE_HOME`). Each row is:

```
[HH:MM:SS] #<mako-id> | <App name> | <message> | <sound-file-or-"silent">
```

Previously this lived at `/tmp/mako-sounds.log`, which Arch's default `tmpfs /tmp` wipes on every reboot — easy to lose history for months without noticing. The new path survives reboots; the old `/tmp` log was copied over on migration to preserve continuity.

Quick filters:

```bash
LOG=~/.local/state/mako-sounds/mako-sounds.log
grep ' | Chromium | '         "$LOG" | tail -20   # all Chromium toasts today
grep -F '#orders'             "$LOG"              # one Slack channel
grep -F '| silent$'           "$LOG"              # suppressed by a rule
awk -F' \\| ' '{print $(NF)}' "$LOG" | sort | uniq -c | sort -rn   # sound-file histogram
```

#### Editing rules

Edit `~/.local/bin/mako-sounds.sh`. Rules are Bash associative arrays near the top (`APP_SOUNDS`, `CONTENT_SOUNDS`, `DEFAULT_SOUND`). Add `[substring]="some-sound.oga"` or `[substring]="silent"` to `CONTENT_SOUNDS` for new patterns. After editing, restart the service so the new rules are live:

```bash
systemctl --user restart mako-sounds
```

The `seen` file means past notifications are **not** replayed after restart — only new ones trigger sounds.

#### Reverting mako-sounds

```bash
systemctl --user disable --now mako-sounds.service
rm ~/.config/systemd/user/mako-sounds.service
systemctl --user daemon-reload

# Script itself stays at ~/.local/bin/mako-sounds.sh — you can still run it
# manually via: nohup ~/.local/bin/mako-sounds.sh & disown
# (before-rewrite copy: ~/.local/bin/mako-sounds.sh.bak.<timestamp>)
```

## Journal changelog

| Date | Entry |
| --- | --- |
| 2026-04-18 | README created; [Additional programs → pwgen](#pwgen) documented for Intel (`sudo pacman -S pwgen`). |
| 2026-04-18 | [Lab network](#lab-network-this-repo): `.112` this host, `.125` remote; SSH probe from agent → **timeout**; verify locally (see table above). |
| 2026-04-18 | [Accessing other Omarchies](#accessing-other-omarchies): `ping` / `ssh -v`, then `openssh` + `sshd.service` on the remote. |
| 2026-04-18 | [Accessing other Omarchies](#accessing-other-omarchies): Omarchy includes `openssh` by default; `systemctl start sshd` to run the server, `enable --now` for boot. |
| 2026-04-18 | [Firewall](#firewall): UFW on Intel remote; default rules table; `sudo ufw allow 22/tcp`. |
| 2026-04-18 | [Installing programs](#installing-programs): `pacman -Q` / `command -v`; `pwgen` on `.112` verified. |
| 2026-04-18 | SSH key to `eugene@192.168.1.202` works; `pacman -Q pwgen` on `.202` → **not installed** (vs `.201`). |
| 2026-04-18 | [Installing programs → pwgen](#pwgen): what it’s for, `pacman -S`, `ssh -t` for remote install; remote install not run by agent (sudo password). |
| 2026-04-18 | [Chromium](#chromium): install 1Password extension. |
| 2026-04-18 | [Installing programs → telegram-desktop](#telegram-desktop): Super+Shift+Space, `inst`, Install menu, `telegram-desktop`. |
| 2026-04-18 | [About application icons in the Waybar](#about-application-icons-in-the-waybar): Waybar intro; Telegram & 1Password tray; less-than key expands tray. |
| 2026-04-18 | [Installing programs](#installing-programs): UI ≈ `pacman`; AUR builds; [Slack](#slack) options. |
| 2026-04-18 | [Slack](#slack): check AUR vote counts when choosing packages (e.g. `slack-desktop` vs `slack-desktop-wayland`). |
| 2026-04-18 | [Waybar font size](#waybar-font-size): enlarged text while tuning Mac (AARCH64) and Intel; `~/.config/waybar/`. |
| 2026-04-19 | [Waybar font size](#waybar-font-size): `style.css` diff `.112` (20px + extra `#custom-*`) vs `.125` (12px). |
| 2026-04-19 | [Omarchy customization scripts](#omarchy-customization-scripts): `apply-` / `revert-omarchy-customizations.sh`. |
| 2026-04-19 | [Waybar tray expander](#waybar-tray-expander): `modules-right` uses **`tray`** instead of **`group/tray-expander`**; scripts + marker index. |
| 2026-04-19 | [Omarchy customization scripts](#omarchy-customization-scripts): **Intel-only** apply/revert; Mac = experiment; marker explained for **stock Intel** undo (not Mac). |
| 2026-04-19 | [Waybar tray expander](#waybar-tray-expander): **`tray.icon-size` 12→20** on Intel; two-line marker; troubleshooting if chevron persists (apply not run / Omarchy reset). |
| 2026-04-19 | [SSH, sudo, and root](#ssh-sudo-and-root): **`ssh`** without **`-t`**; **`pacman`** steps manual as root; no **`sudo`** in remote scripts. |
| 2026-04-19 | [Omarchy customization scripts](#omarchy-customization-scripts): remote payload in **`scripts/remote/*.sh`**. |
| 2026-04-19 | [Chromium → New setups](#new-setups-services-chromium-account-and-profiles): **Services** → **Chromium Account**, then **Add** Chromium **profiles**. |
| 2026-04-21 | [Lan Mouse](#lan-mouse): documented current `.112` ↔ `.125` `left`/`right` setup; [Adding another machine to the right](#adding-another-machine-to-the-right) chains a third host via `.125`. |
| 2026-04-21 | [Idle timers (hypridle)](#idle-timers-hypridle): inventory of `~/.config/hypr/hypridle.conf` listeners; **screensaver at 60 s verified** (edit + `pkill hypridle && hyprctl dispatch exec hypridle`); DPMS-off at 120 s **did not fire** — investigation pending. |
| 2026-04-21 | [Idle timers (hypridle)](#idle-timers-hypridle): experiment reverted → **stock values kept** (DPMS `330 s` / **5.5 min**, screensaver `900 s` / **15 min**). [DPMS vs screensaver](#dpms-vs-screensaver): DPMS = hardware monitor off; screensaver = userland fullscreen `tte` terminal. **Ordering gotcha** — inverting to screensaver-first blocks the later DPMS `Idled` event (reproduced with `hypridle -v`); keep DPMS short and screensaver long. |
| 2026-04-21 | [Installing programs → exfatprogs](#exfatprogs): `sudo pacman -S exfatprogs` for cross-platform exFAT (Linux/Windows/macOS) USB/SD use; verified `1.3.2-1` on **`.112`** and **`.125`**. |
| 2026-04-21 | [Notifications: do-not-disturb on a schedule](#notifications-do-not-disturb-on-a-schedule): new `omarchy-dnd` wrapper + two `systemd --user` timers (`Mon..Fri 17:00 → on`, `Mon..Fri 08:00 → off`, weekends covered for free); reuses Omarchy's stock mako `[mode=do-not-disturb]` and Waybar moon indicator; new keybind **`SUPER + ALT + N`**; mutes Chromium-family browser sink-inputs while DND is on. **Calendar exception skipped** (every Chromium PWA notification reports `App name: Chromium` so no clean rule). |
| 2026-04-22 | [Notifications: do-not-disturb on a schedule](#notifications-do-not-disturb-on-a-schedule): enlarged the Waybar moon icon — split `#custom-notification-silencing-indicator` out of the `font-size: 10px` indicator group into its own block at `font-size: 20px` to match the bar's native `*` size (and the right-side custom icons documented in [Waybar font size](#waybar-font-size)). |
| 2026-04-22 | [Notification sounds (mako-sounds)](#notification-sounds-mako-sounds): daemonised `~/.local/bin/mako-sounds.sh` as `mako-sounds.service` (`Restart=on-failure`, `After=graphical-session.target`); state + log moved from `/tmp` (wiped on reboot) to **`~/.local/state/mako-sounds/`** (`mako-sounds.log`, `seen`); old `/tmp` log preserved by copy; rewrote `tee` path to rely on systemd's `StandardOutput=append:` instead. Service confirmed `active (running)` at 07:27 SAST. |
| 2026-04-22 | [Lan Mouse → Running the daemon (not just the UI)](#running-the-daemon-not-just-the-ui): plain `lan-mouse` runs GUI + daemon in one process — closing the window stopped cursor crossing. Packaged Arch build ships no user service. Added `~/.config/systemd/user/lan-mouse.service` (`ExecStart=/usr/bin/lan-mouse --daemon`, `Restart=on-failure`, `After=graphical-session.target`); `active (running)`, UDP `4242` bound. Noted Hyprland falls back from `input-capture-portal` to `layer-shell` (expected). Release combo **`Ctrl+Shift+Super+Alt`**. |
| 2026-04-22 | [Lan Mouse](#lan-mouse): discovered that on `lan-mouse 0.10.0` the `[client.*]` blocks in `~/.config/lan-mouse/config.toml` are **not** loaded as live peers — CLI REPL returned `no such client: 0` on a fresh daemon. Neighbours must be registered via `connect <edge> <host> <port>` + `activate <id>` (CLI control socket or GUI "Add client"). Added `~/.local/bin/lan-mouse-apply-clients` (pipes those two lines into `lan-mouse -f cli`) and wired it as `ExecStartPost=` on `lan-mouse.service`, so the right-edge peer `192.168.1.202:4242` survives daemon / reboot cycles. Post-start CLI check now reports `client 0: 192.168.1.202:4242 (right), active: true`. Rewrote Lan Mouse section (gotcha box, troubleshooting row, adding-another-machine flow) and left `config.toml` as documentation only with a header comment. |
| 2026-04-22 | [Installing programs → TablePlus (ARM64 AppImage)](#tableplus-arm64-appimage): downloaded upstream ARM64 AppImage, made it executable, and confirmed TablePlus launches successfully on-screen on this AARCH64 machine. |
| 2026-04-22 | [Chromium → Audio troubleshooting](#audio-troubleshooting-no-sound-after-reboot): added a short no-audio-after-reboot playbook for PipeWire/WirePlumber with `wpctl` + `pactl` routing, sink/stream unmute, and Bluetooth recovery (`systemctl restart bluetooth` + reconnect). |
| 2026-04-22 | Added `scripts/audio-route.sh` to switch audio output in one command (`soundcore` / `jabra`), set default sink, unmute/set volume, and move active sink-input streams. |
# omarchy
