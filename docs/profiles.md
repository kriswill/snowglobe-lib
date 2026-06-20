# Profiles

Profiles are curated feature bundles, each toggled with a single `enable`. Turn one on in your host config:

```nix
snowglobe-lib.profiles.gaming.enable = true;
```

The [installer](cli.md) offers all six interactively. All values are `setDefault` (freely overridable) **unless noted** — a few profiles use plain `lib.mkDefault` or hard `true`/`false`, which are called out below because they matter for overriding.

| Profile | Option | One-liner |
|---|---|---|
| [gaming](#gaming) | `snowglobe-lib.profiles.gaming.enable` | Steam + the Linux gaming stack. |
| [office](#office) | `snowglobe-lib.profiles.office.enable` | LibreOffice, Thunderbird, a CUPS printing stack. |
| [hacker-mode](#hacker-mode) | `snowglobe-lib.profiles.hacker-mode.enable` | A Kali-style pentest/security toolkit. |
| [harden](#harden) | `snowglobe-lib.profiles.harden.enable` | Firewall, no-password SSH, immutable users. |
| [nix-tools](#nix-tools) | `snowglobe-lib.profiles.nix-tools.enable` | A Nix developer toolbox. |
| [hardware-tools](#hardware-tools) | `snowglobe-lib.profiles.hardware-tools.enable` | Hardware diagnostics & sensors. |

---

## gaming

> "utilities for that OOB Linux gaming experience"

Enables a full gaming stack:

- **Steam** (`programs.steam.enable`) with `gamescopeSession.enable` and `localNetworkGameTransfers.openFirewall`. *(Steam is proprietary; this opens a firewall port for local game transfers.)*
- **Proton management:** `protonup-qt`, plus `protonup-ng` in system packages.
- **Lutris** — game/emulator frontend.
- **MangoHud** — performance overlay.
- **xclicker** — autoclicker (works under XWayland).
- **OpenRGB** (`services.hardware.openrgb`) with `motherboard = system.cpu-vendor`.
- `hardware.xone.enable` — Xbox controller dongle support.

Also: [`gpu/common.nix`](desktops.md#gpu) turns on `services.lact` (GPU monitor/control) when `gaming` or `hardware-tools` is enabled.

> A `# TODO gamemode` notes gamemode is not yet wired in.

---

## office

> "tools and programs typically found in an office setting"

- **Printing:** `services.printing` with `hplip` (HP), `gutenprint` (Ghostscript), `splix` (Samsung) drivers; `browsed` off. Plus `services.avahi` (`nssmdns4`, `openFirewall`) for network printer discovery. *(`avahi.openFirewall` opens mDNS ports.)*
- **Apps:** `thunderbird` (email), `libreoffice` (the office suite — package already defaulted to `libreoffice-fresh` by core), `chromium` (backup browser).

---

## hacker-mode

> "Snowglobe-Lib's cybersecurity suite. Installs a majority of tools present on Kali." (Code comment: "basically turns nixos into kali linux.")

Tools (here set with plain `lib.mkDefault`, not `setDefault`):

- **Always:** `tcpdump`, `metasploit`, `lynx`, `binsider`, `wireshark` (CLI), `traceroute`, `nmap`, `john` (John the Ripper); plus `binutils`, `dnsutils` in system packages.
- **When a desktop is enabled** (`snowglobe-lib.desktop.enable`): `ghidra`, `zenmap` (nmap GUI), `tor-browser`, and the **GUI** Wireshark (`wireshark.package = pkgs.wireshark`).

---

## harden

> "Snowglobe-Lib's hardening configuration for increased system security"

A small, high-impact set:

| Setting | Value | Helper |
|---|---|---|
| `networking.firewall.enable` | `true` | **hard** |
| `networking.firewall.allowPing` | `false` | `setDefault` |
| `users.mutableUsers` | `false` | `setDefault` |
| `services.openssh.settings.PasswordAuthentication` | `false` | **hard** |
| `services.openssh.settings.KbdInteractiveAuthentication` | `false` | **hard** |

> **Security callouts:**
> - `users.mutableUsers = false` means users are managed **only** declaratively — set `hashedPasswordFile` / `hashedPassword` or you'll lock yourself out. The installer warns that a `wheel` user with no password can't `sudo` under this profile.
> - SSH password auth is hard-disabled — configure SSH keys (e.g. via [`keyring.ssh`](options.md#keyring)) before enabling this on a remote box.
> - `boot.kernelPackages = pkgs.linuxPackages_hardened` is present but **commented out**.

---

## nix-tools

> "Snowglobe-Lib's choice of tools for development with nix" (the installer recommends it for developers)

- **Programs:** `nix-output-monitor`, `nix-index-database` (+ `comma`), `nix-fast-build`, `nvd`, `nh`, `direnv`.
- **Packages:** `nurl`, `nix-prefetch-git`, `deadnix`, `nixpkgs-hammering`, `statix`, `nix-init`, `nix-update`, `nixpkgs-review`, `nixfmt`.

---

## hardware-tools

> "hardware diagnostic tools"

- `programs.corefreq.enable` (CPU monitoring).
- Diagnostics in system packages: `usbutils`, `smartmontools`, `hdparm`, `nvme-cli`, `lm_sensors`, `pciutils`, `lshw`, `hwinfo`, `inxi`, `vdpauinfo`, `libva-utils`, `mesa-demos`, `vulkan-tools`, `clinfo`.

Also turns on `services.lact` via [`gpu/common.nix`](desktops.md#gpu) when a GPU module is active.

---

See also: **[options.md](options.md)** · **[desktops.md](desktops.md)** · **[programs.md](programs.md)**.
