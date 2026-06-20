# Getting started

There are two ways onto snowglobe-lib:

- **[A. Install from the ISO](#a-install-from-the-iso)** — the guided path. A live image scaffolds a fresh flake repo for you and installs NixOS. Best for a new machine or your first snowglobe.
- **[B. Consume it as a flake input](#b-consume-it-as-a-flake-input)** — wire snowglobe-lib into a flake you write by hand. Best if you already have a config or want full control of the layout.

Both end up in the same place: a flake that calls [`mkNixosHost`](host-builder.md), and a system you maintain with [`snowglobe-rebuild`](#day-2-rebuilding).

---

## A. Install from the ISO

### 1. Build the installer image

From a checkout of this repo:

```sh
nixos-rebuild build-image --image-variant iso-installer --flake .#snowglobe-installer-x86_64
# → ./result/iso/*.iso
```

Variants (`nixosConfigurations/default.nix`):

| Flake attribute | Image |
|---|---|
| `snowglobe-installer-x86_64` | Base installer. |
| `snowglobe-installer-x86_64-untrusted` | Doesn't trust the maintainer binary cache (sets `CACHE_UNTRUSTED=1`, so the installed system opts out too). |
| `snowglobe-installer-x86_64-small` | Omits redistributable/all firmware — smaller image, for VMs or known hardware. |
| `snowglobe-installer-x86_64-small-untrusted` | Both of the above. |

Write `./result/iso/*.iso` to a USB stick (e.g. with `dd`) and boot it.

### 2. Run the installer

Become root and run the bundled script:

```sh
sudo install.sh
```

The installer (`lib/scripts/snowglobe-install.sh`) is interactive and walks you through:

1. **Connectivity** — offers `nmtui` if you're offline.
2. **Disks** — partitions via disko (default GPT: 1M BIOS-boot + 512M ESP + ext4 root), with optional **LUKS** encryption. You can drop a custom disko file under `/etc/disko` instead.
3. **Hardware detection** — firmware (UEFI/BIOS), CPU vendor, VM?, GPU vendors, arch, NixOS version — all detected and written into your `mkNixosHost` call.
4. **Locale / keyboard / timezone** — defaults `en_US.UTF-8` / `us` / dynamic (geolocation).
5. **Desktop** — KDE, Niri, labwc, Hyprland, or none.
6. **Profiles** — `hardware-tools`, `gaming`, `office`, `hacker-mode`, `nix-tools`, `harden` (harden defaults **yes**).
7. **Flake scaffold** — writes a complete starter repo at `/mnt/etc/nixos` (`flake.nix`, `nixosConfigurations/`, `nixosModules/default/`, `overlays/`, `packages/`, `devshell.nix`).
8. **Secrets** — generates an **age** key, sets up `.sops.yaml` and a `keyring.nix`, and records the key. **Back up the private age key** (`/mnt/root/.config/sops/age/keys.txt`) — lose it and you lose your secrets and the ability to rebuild.
9. **Users** — usernames, passwords (hashed into sops), SSH keys, `wheel`/`networkmanager` membership.
10. **Install** — runs `nixos-install` and offers to reboot.

The full step-by-step (including reinstall and "append a host to an existing repo" modes) is in **[cli.md](cli.md#snowglobe-installsh--end-to-end-installer-flow)**.

### 3. The repo it produces

The scaffolded flake is the canonical consumer shape:

```
/etc/nixos/
├── flake.nix                       # pins snowglobe-lib, exposes nixosConfigurations + your overlays/packages
├── .sops.yaml                      # age recipients + creation rules
├── nixosConfigurations/
│   ├── default.nix                 # { flake }: { <host> = slib.mkNixosHost { … }; }
│   └── <host>/
│       ├── configuration.nix       # snowglobe-lib.desktop.* / profiles.* + locale/keyboard
│       ├── hardware-configuration.nix
│       ├── disko.nix
│       ├── secrets.yaml            # sops-encrypted
│       └── users/<user>/default.nix
├── nixosModules/default/           # your own shared modules (+ keyring.nix)
├── overlays/default.nix            # your overlays (+ snowglobe-lib's, re-exported)
├── packages/default.nix            # your custom derivations
└── devshell.nix
```

From here you maintain it like any flake — edit and run `snowglobe-rebuild switch` (see [below](#day-2-rebuilding)).

---

## B. Consume it as a flake input

Only **two things** are required to consume snowglobe-lib: pin it as an input, and realize a host with `mkNixosHost`. Everything else is your choice.

### 1. Pin the input

```nix
inputs = {
  snowglobe-lib.url = "git+https://codeberg.org/earthgman/snowglobe-lib?ref=unstable";

  # Use the SAME nixpkgs snowglobe-lib was written against. Strongly recommended:
  # avoids a second nixpkgs in the store and guarantees the modules evaluate
  # against the rev they target.
  nixpkgs.follows = "snowglobe-lib/nixpkgs";
};
```

- `?ref=unstable` selects the `unstable` branch; drop the query string to track the default branch. (To build from the [kriswill fork](../README.md#upstream--this-fork), use `git+https://codeberg.org/kriswill/snowglobe-lib?ref=unstable`.)
- To pin your **own** nixpkgs instead, give snowglobe-lib `inputs.nixpkgs.follows = "nixpkgs"` and declare your own `nixpkgs` input. The framework warns this "could cause instabilities."
- snowglobe-lib already carries `import-tree`, `disko`, `sops-nix`, `nixos-hardware`, `nix-index-database`, `nix-post-build-hook-queue`, `flux`, and `jovian-nixos` — reuse them with `<input>.follows = "snowglobe-lib/<input>"` rather than re-declaring.

### 2. Realize a host

The simplest possible consumer:

```nix
{
  inputs = {
    snowglobe-lib.url = "git+https://codeberg.org/earthgman/snowglobe-lib?ref=unstable";
    nixpkgs.follows = "snowglobe-lib/nixpkgs";
  };

  outputs = { self, snowglobe-lib, ... }@inputs: {
    nixosConfigurations.myhost = snowglobe-lib.lib.mkNixosHost {
      hostname     = "myhost";
      cpu-vendor   = "amd";
      gpu-vendors  = [ "nvidia" ];
      firmware     = "UEFI";
      stateVersion = "26.05";

      configDir   = ./hosts/myhost;   # import-tree'd; ./hosts/myhost/secrets.yaml auto-wired
      modules     = [ ./hosts/myhost/hardware-configuration.nix ];

      # mkNixosHost does NOT inject `inputs`; add it if your modules expect it:
      specialArgs = { inherit inputs; };
    };
  };
}
```

See **[host-builder.md](host-builder.md)** for every argument and how `configDir` works.

### 3. Turn features on

Inside the module you pass (e.g. `./hosts/myhost/configuration.nix`), set `snowglobe-lib.*` options. Hardware facts (`cpu-vendor`, `gpu-vendors`, …) come from the `mkNixosHost` arguments, so here you mostly pick **desktops** and **profiles**:

```nix
{ ... }:
{
  # plain NixOS
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone      = "America/Los_Angeles";

  # a Wayland desktop (see docs/desktops.md)
  snowglobe-lib.desktop.niri.enable = true;

  # curated bundles (see docs/profiles.md)
  snowglobe-lib.profiles.gaming.enable    = true;
  snowglobe-lib.profiles.office.enable    = true;
  snowglobe-lib.profiles.harden.enable    = true;
  snowglobe-lib.profiles.nix-tools.enable = true;
}
```

To **override** any framework default, just assign the option normally — almost everything is set at `setDefault` priority:

```nix
hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.production;  # beat the beta default
services.polkit-gnome.enable = false;                                           # run your own polkit agent
substituters."nix-store.earthgman.dev".enable = false;                          # opt out of the cache
```

See **[architecture.md](architecture.md#the-override-weight-ladder)** for why this never conflicts.

### Your modules vs. snowglobe-lib's modules

Two module sets merge into one system:

- **snowglobe-lib's modules** — injected automatically by `mkNixosHost`. They *declare and implement* the `snowglobe-lib.*` option tree and pull in disko/sops-nix/nix-index-database/overlays. You **consume** them by setting options; you don't import them.
- **Your modules** — everything you pass via `modules`/`configDir`. Ordinary NixOS modules that *set* snowglobe options and add anything snowglobe doesn't cover.

### A note on the "dendritic" layout

The reference consumer (a personal config for host `nebula`) wraps all this in a [flake-parts](https://flake.parts) + `import-tree` "dendritic" layout: a `configurations.nixos.<host>` registry, a `flake.modules.nixos.*` shared-module registry, and `deferredModule`-merged host files. **None of that is a snowglobe-lib requirement** — it's that repo's own organizational taste. A plain `flake.nix` with a hand-written `nixosConfigurations` attrset (as above) consumes snowglobe-lib just as well.

---

## Day-2: rebuilding

Once installed, `programs.snowglobe-rebuild` is enabled by default. Use it exactly like `nixos-rebuild`:

```sh
cd /etc/nixos          # or wherever your flake lives
snowglobe-rebuild switch --flake .#myhost
```

On `switch`/`boot` it keeps your repo synced with git (stash → pull → restage across a fleet), uses `nh os` when available, logs the new generation to `updates.log`, then prompts for a commit message and pushes. Full behavior and flags: **[cli.md](cli.md#snowglobe-rebuild)**.

> **Path gotcha:** `nixos-rebuild --flake <path>` (and therefore `snowglobe-rebuild`) does not follow a `<path>` that is itself a symlink. `cd` into the real checkout first and use `.#<host>`.

---

See also: **[host-builder.md](host-builder.md)** · **[options.md](options.md)** · **[profiles.md](profiles.md)** · **[desktops.md](desktops.md)**.
