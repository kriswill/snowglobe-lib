# snowglobe-lib

A **NixOS "snowglobe"** — a complete, opinionated NixOS distribution that you pull in as a *single flake input* and switch on with one line:

```nix
snowglobe-lib.enable = true;
```

Unlike a typical à-la-carte module collection, snowglobe-lib ships a whole batteries-included system: the [Lix](https://lix.systems) daemon, a hardened/degoogled application set (LibreWolf, Vesktop, ungoogled-chromium), a full Wayland desktop stack (Niri, Hyprland, labwc, or KDE Plasma 6), **150+ pre-wrapped `programs.*` modules**, curated feature **profiles** (gaming, office, hacker-mode, harden, nix-tools, hardware-tools), an interactive ISO **installer**, declarative disks ([disko](https://github.com/nix-community/disko)) and secrets ([sops-nix](https://github.com/Mic92/sops-nix)), and a git-synced rebuild wrapper.

The whole opinionated configuration sits inside a sealed globe. **Every default the framework sets is applied at a *weaker-than-`mkDefault`* priority**, so any single line in your own config overrides any framework default — with zero "conflicting definition" errors. Pick it up, shake it (`mkNixosHost`), and you have a working machine; reach in and change anything without fighting the framework.

> **Opinionated like a distro, overridable like raw NixOS.** That one idea — implemented by the [override-weight ladder](#the-override-weight-model) — is the thing to understand before anything else.

---

## Table of contents

- [What you get](#what-you-get)
- [Two ways to use it](#two-ways-to-use-it)
  - [A. Install from the ISO](#a-install-from-the-iso-guided)
  - [B. Consume it as a flake input](#b-consume-it-as-a-flake-input)
- [The override-weight model](#the-override-weight-model)
- [The option surface at a glance](#the-option-surface-at-a-glance)
- [Repository layout](#repository-layout)
- [Status, scope & the binary cache](#status-scope--the-binary-cache)
- [Documentation](#documentation)
- [Upstream & this fork](#upstream--this-fork)

---

## What you get

| Area | What snowglobe-lib provides |
|---|---|
| **Host builder** | `mkNixosHost` — one function that turns hardware facts (CPU/GPU vendor, firmware, VM?) into a complete `nixosSystem`. |
| **Nix stack** | Lix daemon, flakes on, channels off, `auto-optimise-store`, `nh` with periodic GC, a signed binary cache. |
| **Desktops** | Niri, Hyprland, labwc (DIY Wayland), or KDE Plasma 6 — each one switch (`snowglobe-lib.desktop.<wm>.enable`) that wires the compositor, greeter, portals, audio, Bluetooth, and default apps. |
| **GPU** | AMD / Intel / NVIDIA drivers auto-enabled from a vendor list. |
| **Profiles** | `gaming`, `office`, `hacker-mode`, `harden`, `nix-tools`, `hardware-tools` — curated bundles toggled with one `enable`. |
| **Program modules** | 150+ programs wrapped in a uniform schema (`enable` / `package` / `installGlobally` / `installForUsers`) so installing anything is consistent and per-user-aware. |
| **Installer** | A live ISO with an interactive installer that detects hardware, scaffolds your flake repo, sets up users + sops secrets, and runs `nixos-install`. |
| **Secrets & keys** | sops-nix (age) defaults plus a `keyring.*` registry for named public keys. |
| **Day-2 ops** | `snowglobe-rebuild`, a `nixos-rebuild` wrapper that keeps your config synced and committed to git and logs every generation. |
| **Packages & overlays** | Custom fonts, a GRUB theme, a Core Keeper server, vim plugins, and in-place patches for a handful of packages — all exposed via `pkgs` and as flake `packages`. |

Built on [flake-parts](https://flake.parts)-free plain flake outputs plus [`import-tree`](https://github.com/vic/import-tree) for module auto-discovery. Targets `x86_64-linux` and `aarch64-linux`, tracking `nixpkgs-unstable`.

---

## Two ways to use it

### A. Install from the ISO (guided)

Build the live installer image and write it to a USB stick:

```sh
# from a checkout of this repo
nixos-rebuild build-image --image-variant iso-installer --flake .#snowglobe-installer-x86_64
# → ./result/iso/*.iso
```

Boot it, become root, and run the installer:

```sh
sudo install.sh
```

It detects your hardware, lets you pick a desktop and profiles, scaffolds a brand-new flake repo at `/mnt/etc/nixos`, generates an age key + sops secrets, creates your users, and installs. Variants exist for slim images (`-small`) and for opting out of the maintainer cache (`-untrusted`). See **[docs/getting-started.md](docs/getting-started.md)** and **[docs/cli.md](docs/cli.md)** for the full flow.

### B. Consume it as a flake input

The minimal consumer — pin the input, then realize a host with `mkNixosHost`:

```nix
{
  inputs = {
    snowglobe-lib.url = "git+https://codeberg.org/earthgman/snowglobe-lib?ref=unstable";
    # use the SAME nixpkgs snowglobe-lib was written against (recommended):
    nixpkgs.follows = "snowglobe-lib/nixpkgs";
  };

  outputs = { self, snowglobe-lib, ... }@inputs: {
    nixosConfigurations.myhost = snowglobe-lib.lib.mkNixosHost {
      hostname     = "myhost";
      cpu-vendor   = "amd";              # "amd" | "intel" | null
      gpu-vendors  = [ "nvidia" ];       # any of "amd" "intel" "nvidia"
      firmware     = "UEFI";             # "UEFI" | "BIOS"
      stateVersion = "26.05";
      configDir    = ./hosts/myhost;     # import-tree'd; ./hosts/myhost/secrets.yaml auto-wired
      specialArgs  = { inherit inputs; };
    };
  };
}
```

Then, in `./hosts/myhost/configuration.nix`, turn on the features you want:

```nix
{ ... }:
{
  snowglobe-lib.desktop.niri.enable = true;     # a Wayland desktop
  snowglobe-lib.profiles.gaming.enable = true;  # steam, lutris, mangohud, …
  snowglobe-lib.profiles.harden.enable = true;  # firewall, no-password SSH, immutable users
}
```

`mkNixosHost` injects the entire framework, sets `snowglobe-lib.enable = true`, and feeds your hardware facts into `snowglobe-lib.system.*`. Everything else is ordinary NixOS config. A full walkthrough — including the larger "dendritic" layout used by the reference consumer — is in **[docs/getting-started.md](docs/getting-started.md)**; the builder's full signature is in **[docs/host-builder.md](docs/host-builder.md)**.

---

## The override-weight model

This is the load-bearing concept. In the NixOS module system a **lower priority number wins**. snowglobe-lib sets almost everything through three helpers from its `lib`:

```
50    mkForce                  ← you (hard override — always wins)
100   plain assignment         ← you (normal config — wins over everything below)
899   overrideNixpkgsDefault   ← framework, beats a nixpkgs mkDefault
1000  mkDefault                ← you / nixpkgs (soft default)
1336  overrideDefault          ← framework, overrides its own setDefault
1337  setDefault               ← framework, the weakest default in the stack
```

| Helper | `mkOverride` weight | Why |
|---|---|---|
| `setDefault` | `1337` | The framework's standard "soft default." Weaker than `mkDefault`, so your plain `option = value;` silently wins — no conflict. |
| `overrideDefault` | `1336` | Lets one framework module override another's `setDefault` while still yielding to you. |
| `overrideNixpkgsDefault` | `899` | For the rare option nixpkgs already pins with `mkDefault` (e.g. `/bin/sh`, default shell): slips just under `1000` to assert the framework's choice, while your normal assignment (`100`) still wins. |

The payoff: you get a fully-configured system that behaves like a set of *suggestions*, never a set of *locks*. To change any framework default, just assign the option normally. Details and worked examples: **[docs/architecture.md](docs/architecture.md#the-override-weight-ladder)**.

---

## The option surface at a glance

| Option | Purpose | Reference |
|---|---|---|
| `snowglobe-lib.enable` | The master switch. Off does nothing; on applies the whole opinionated baseline. | [options](docs/options.md) |
| `snowglobe-lib.system.{cpu-vendor,gpu-vendors,firmware,isVM,hasDesktop}` | Host facts other modules read (usually set for you by `mkNixosHost`). | [options](docs/options.md#snowglobe-libsystem) |
| `snowglobe-lib.desktop.{niri,hyprland,labwc,kde}.enable` | Pick a desktop; pulls in the shared desktop base + that WM's defaults. | [desktops](docs/desktops.md) |
| `snowglobe-lib.desktop.{enable,installWaylandDeps}` | The shared desktop base (audio, portals, Bluetooth, greeter, fonts). | [options](docs/options.md#snowglobe-libdesktop) |
| `snowglobe-lib.gpu.{amd,intel,nvidia}.enable` | Per-vendor GPU config (auto-derived from `gpu-vendors`). | [desktops](docs/desktops.md#gpu) |
| `snowglobe-lib.profiles.{gaming,office,hacker-mode,harden,nix-tools,hardware-tools}.enable` | Curated feature bundles. | [profiles](docs/profiles.md) |
| `snowglobe-lib.{boot-config,dynamic-timezone,headless-debloater,libvirtd-qemu}` | Supporting toggles (GRUB, geo-timezone, headless slimming, libvirt/QEMU). | [options](docs/options.md) |
| `programs.<name>.{enable,package,installGlobally,installForUsers}` | The uniform program-module schema across 150+ programs. | [programs](docs/programs.md) |
| `substituters.<host>.{enable,publicKey,priority}` | A friendlier way to register/toggle binary caches. | [options](docs/options.md#substituters) |
| `keyring.{ssh,age,openpgp}` | A named registry of public keys to reuse across your config. | [options](docs/options.md#keyring) |

---

## Repository layout

```
.
├── flake.nix                       # all outputs: lib, nixosModules, nixosConfigurations, overlays, packages, devShells
├── devshell.nix                    # dev shell (ci.sh + snowglobe-rebuild)
├── lib/
│   ├── functions/                  # the public `lib`
│   │   ├── flake-helpers/           #   mkNixosHost
│   │   └── module-wrappers/         #   mkProgramOption, installProgram, mkGraphicalService, mkProgramAlias, setDefault…
│   ├── mixins/disko/               # default-ext4{,-luks}.nix partition layouts
│   ├── scripts/                    # snowglobe-install.sh, snowglobe-rebuild.sh, ci.sh
│   └── templates/program-module.nix
├── nixosModules/
│   ├── snowglobe-lib/              # the framework: enable gate, system/desktop options, gpu/, desktops/, profiles/
│   ├── nixos/                      # upstream patches + program modules (programs/, services/), keyring, substituters
│   └── jovian/                     # opt-in Steam Deck / Jovian config
├── nixosConfigurations/            # reference hosts: the installer ISO(s) + testmonkey CI host
├── overlays/                       # custom packages + package-patches + extra vimPlugins
└── packages/                       # custom derivations (fonts, grub theme, snowglobe-rebuild, …)
```

A deeper tour is in **[docs/architecture.md](docs/architecture.md)**.

---

## Status, scope & the binary cache

- **NixOS only**, `x86_64-linux` / `aarch64-linux`, tracking **nixpkgs-unstable** (a `nixpkgs-stable` on `nixos-26.05` is wired in for patches). Uses the **Lix** daemon by default.
- Enabling `snowglobe-lib` trusts a maintainer-run binary cache, **`nix-store.earthgman.dev`** (priority `100`, below `cache.nixos.org`), which serves the framework's patched packages. You can disable it per-host: `substituters."nix-store.earthgman.dev".enable = false;` (this is exactly what the `-untrusted` installer variant does). See **[docs/options.md#substituters](docs/options.md#substituters)**.
- This is a single-maintainer framework with opinionated defaults and a handful of known rough edges — see **[docs/known-issues.md](docs/known-issues.md)** before relying on it in production.

---

## Documentation

Everything lives in **[`docs/`](docs/)**:

| Doc | Covers |
|---|---|
| [docs/getting-started.md](docs/getting-started.md) | Install from ISO **and** consume as a flake input; day-1 → day-2. |
| [docs/architecture.md](docs/architecture.md) | Flake inputs/outputs, module composition, `import-tree`, the `enable` gate, the override-weight ladder. |
| [docs/host-builder.md](docs/host-builder.md) | `mkNixosHost` — full argument reference and `configDir`/secrets behavior. |
| [docs/options.md](docs/options.md) | The `snowglobe-lib.*` option tree, the core defaults `enable` applies, substituters, keyring. |
| [docs/profiles.md](docs/profiles.md) | The six profiles and exactly what each one turns on. |
| [docs/desktops.md](docs/desktops.md) | Niri / Hyprland / labwc / KDE desktop modules and the GPU modules. |
| [docs/programs.md](docs/programs.md) | The program-module framework and the full 150+ catalog. |
| [docs/authoring.md](docs/authoring.md) | Extending snowglobe-lib: new program modules, graphical services, aliases, packages, overlays, caches, disko mixins. |
| [docs/packages-and-overlays.md](docs/packages-and-overlays.md) | Custom packages and the in-place package patches. |
| [docs/cli.md](docs/cli.md) | `snowglobe-rebuild`, the installer internals, and the maintainer `ci.sh`. |
| [docs/known-issues.md](docs/known-issues.md) | Consolidated gotchas, in-code TODOs, and footguns. |

---

## Upstream & this fork

snowglobe-lib originated with **earthgman** ([codeberg.org/earthgman/snowglobe-lib](https://codeberg.org/earthgman/snowglobe-lib)); the binary cache, the installer-generated flake template, and the project namespace all reference that origin. **This repository is the `kriswill` fork** ([codeberg.org/kriswill/snowglobe-lib](https://codeberg.org/kriswill/snowglobe-lib)), tracked on the `unstable` branch.

When pinning snowglobe-lib as an input you may point at whichever fork you build from — the examples in these docs use the upstream `earthgman` URL because that is what the installer scaffolds and what the reference consumer uses. To build from this fork, substitute `git+https://codeberg.org/kriswill/snowglobe-lib?ref=unstable`.

Credits:

- The **snowglobe** concept and framework — earthgman.
- [`import-tree`](https://github.com/vic/import-tree) — module auto-discovery.
- [disko](https://github.com/nix-community/disko), [sops-nix](https://github.com/Mic92/sops-nix), [Lix](https://lix.systems), [nix-index-database](https://github.com/nix-community/nix-index-database), [nix-post-build-hook-queue](https://github.com/newam/nix-post-build-hook-queue), [Jovian-NixOS](https://github.com/Jovian-Experiments/Jovian-NixOS), [flux](https://github.com/iogamaster/flux) — upstream inputs.
