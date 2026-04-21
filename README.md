# Omarchy workstation journal

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
| This machine | `192.168.1.112` | Where you run this Laravel app and local checks (AARCH64). |
| Remote | `192.168.1.125` | Intel Omarchy box—compare via SSH: `ssh eugene@192.168.1.125` |

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
./scripts/apply-omarchy-customizations.sh eugene@192.168.1.125
./scripts/revert-omarchy-customizations.sh eugene@192.168.1.125
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
- [Additional programs](#additional-programs)
- [Chromium](#chromium)
  - [New setups: Services, Chromium account, and profiles](#new-setups-services-chromium-account-and-profiles)
- [About application icons in the Waybar](#about-application-icons-in-the-waybar)
- [Waybar tray expander](#waybar-tray-expander)
- [Waybar font size](#waybar-font-size)

### Accessing other Omarchies

Unlike optional tools such as **`pwgen`**, the **SSH server stack is already part of base Omarchy**: the **`openssh`** package (which provides **`sshd`**) is installed out of the box. What you often need is to **run the daemon**—it may be stopped until you start it.

**From this machine** (e.g. `192.168.1.112`), toward the other host (e.g. `192.168.1.125`):

```bash
ping -c1 192.168.1.125
ssh -v eugene@192.168.1.125
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

Then retry `ssh eugene@192.168.1.125` from `192.168.1.112`. If **`sshd` is active** but SSH from the LAN still hangs or times out, open **TCP 22** on the server’s host firewall—see **[Firewall](#firewall)**.

### Firewall

On the **Intel remote** host (`192.168.1.125`), **`ufw` is active**. Inbound **SSH (TCP 22)** was not in the allow list below, so LAN clients could reach the IP but not complete SSH until port **22** is allowed.

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

Remote check (SSH keys to `eugene@192.168.1.125`):

```bash
ssh eugene@192.168.1.125 'pacman -Q <pkgname>'
```

Installing through the **Omarchy “Install” UI** is still **`pacman`** for official repo packages—same names and result as the terminal. **AUR** installs (when you use an AUR helper or a UI that targets the AUR) usually **build** the package on your machine or run upstream install scripts—slower, needs build tools, and you should trust the `PKGBUILD`.

#### pwgen

**[pwgen](https://linux.die.net/man/1/pwgen)** prints random passwords or passphrases in the terminal—useful for disposable secrets, test fixtures, or one-off strings without leaving the shell.

**Install** (any Omarchy host, local shell):

```bash
sudo pacman -S pwgen
```

**Intel `192.168.1.125` over SSH:** `sudo` needs a password; use a TTY so the prompt works:

```bash
ssh -t eugene@192.168.1.125 'sudo pacman -S pwgen'
```

(Automated non-interactive install from this journal is skipped—remote `sudo` is not passwordless.)

**Status in this journal**

| Host | `pacman -Q pwgen` |
| --- | --- |
| `192.168.1.112` | `pwgen 2.08-3` |
| `192.168.1.125` | not installed until you run the `ssh -t …` install above; then re-check with `ssh eugene@192.168.1.125 'pacman -Q pwgen'`. |

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

### Additional programs

Index of optional **pacman** packages we care about; install/check steps live under **[Installing programs](#installing-programs)**.

- **[pwgen](#pwgen)** — password generator CLI.
- **[telegram-desktop](#telegram-desktop)** — Telegram client (`telegram-desktop`).
- **[Slack](#slack)** — not in core repos; AUR / Flatpak / web.

### Chromium

#### New setups: Services, Chromium account, and profiles

On a **fresh** Omarchy machine, work through **Services** in the Omarchy flow (e.g. **Super** + **Shift** + **Space** → **Install** / onboarding) and install **Chromium Account**—the piece that wires Chromium to **Google account** sign-in and related behaviour. Do that **before** you rely on multiple browser identities.

After **Chromium Account** is installed, open Chromium and use the **profile** menu to **Add** extra **Chromium profiles** (work, personal, client, …). Extensions (including **1Password** in the next paragraph) are **per profile**, so separate profiles keep logins and extensions apart.

**Remember:** install the **[1Password](https://chromewebstore.google.com/detail/1password/aeblfdkhhhdcdjpifhhbdiojplfjncoa)** extension in **Chromium** (Chrome Web Store; Chromium supports the same extension). The store may warn that you should use **Chrome**—you can **ignore that** for Chromium.

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

**`~/.config/waybar/style.css` compared** (`diff` first file = **`192.168.1.112`**, second = **`192.168.1.125`**):

| | **`192.168.1.112` (Mac, AARCH64)** | **`192.168.1.125` (Intel)** |
| --- | --- | --- |
| `*` rule `font-size` | **20px** | **12px** |
| Extra blocks (only on Mac) | `#custom-nightlight`, `#custom-claude`, `#custom-slack`, `#custom-fractal` | — |

Reproduce:

```bash
diff -u ~/.config/waybar/style.css <(ssh eugene@192.168.1.125 'cat ~/.config/waybar/style.css')
```

Unified diff (as captured, 2026-04-19):

```diff
--- style.css (192.168.1.112)
+++ style.css (192.168.1.125)
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

## Journal changelog

| Date | Entry |
| --- | --- |
| 2026-04-18 | README created; [Additional programs → pwgen](#pwgen) documented for Intel (`sudo pacman -S pwgen`). |
| 2026-04-18 | [Lab network](#lab-network-this-repo): `.112` this host, `.125` remote; SSH probe from agent → **timeout**; verify locally (see table above). |
| 2026-04-18 | [Accessing other Omarchies](#accessing-other-omarchies): `ping` / `ssh -v`, then `openssh` + `sshd.service` on the remote. |
| 2026-04-18 | [Accessing other Omarchies](#accessing-other-omarchies): Omarchy includes `openssh` by default; `systemctl start sshd` to run the server, `enable --now` for boot. |
| 2026-04-18 | [Firewall](#firewall): UFW on Intel remote; default rules table; `sudo ufw allow 22/tcp`. |
| 2026-04-18 | [Installing programs](#installing-programs): `pacman -Q` / `command -v`; `pwgen` on `.112` verified. |
| 2026-04-18 | SSH key to `eugene@192.168.1.125` works; `pacman -Q pwgen` on `.125` → **not installed** (vs `.112`). |
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
