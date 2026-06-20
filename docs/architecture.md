# Architecture

snowglobe-lib is a NixOS **snowglobe**: a reusable flake that downstream configurations consume as a single input. It exposes a function library, a set of NixOS modules gated behind one master switch (`snowglobe-lib.enable`), package/overlay outputs, and reference host configurations.

The defining design principle is the **[override-weight ladder](#the-override-weight-ladder)**: every opinionated default is applied at a *weaker-than-`mkDefault`* priority, so consumers can override anything without triggering Nix option conflicts.

- [Flake inputs](#flake-inputs)
- [Flake outputs](#flake-outputs)
- [Module composition](#module-composition)
- [`import-tree`](#import-tree)
- [The `snowglobe-lib.enable` gate](#the-snowglobe-libenable-gate)
- [The override-weight ladder](#the-override-weight-ladder)
- [The `jovian` module](#the-jovian-module)
- [Disabled upstream modules](#disabled-upstream-modules)

---

## Flake inputs

All declared in `flake.nix`. Every input except `import-tree` and `nixos-hardware` follows the framework's `nixpkgs` (unstable) to avoid divergent closures.

| Input | Source | Why it's here |
|---|---|---|
| `nixpkgs` | `nixos-unstable` | Primary package set; provides the `lib` used throughout. |
| `nixpkgs-stable` | `nixos-26.05` | Stable channel, wired into `overlays/package-patches` for patches that need a stable-channel package (plumbing present; nothing consumes it yet). |
| `disko` | nix-community | Declarative disk partitioning. Its module is in the default set; `programs.disko.enable` defaults `true`. |
| `flux` | iogamaster | Provides `mkSteamServer`/`fetchSteam` builders used by the Core Keeper package; re-exposed as `overlays.flux`. |
| `jovian-nixos` | Jovian-Experiments | Steam Deck support. Imported **only** by the opt-in `nixosModules.jovian`. |
| `import-tree` | vic | Recursively auto-imports `.nix` module files. The backbone of module composition. |
| `nixos-hardware` | NixOS (flakehub) | Hardware profiles, re-exposed raw as `nixosModules.nixos-hardware`. |
| `nix-index-database` | nix-community | Prebuilt `nix-index` DB / `command-not-found`. In the default set. |
| `nix-post-build-hook-queue` | newam | Queues store paths for upload to a binary cache after each build. In the default set; overlay re-exposed. (`treefmt.follows = ""` empties that transitive input.) |
| `sops-nix` | Mic92 | Secrets storage / age key management. Added to the default set **separately** from `import-tree` (see below). |

The `outputs` function only destructures `{ nixpkgs, self, ... }`; everything else is reached through `self.inputs` / `self.outputs` (aliased internally as `flake` / `inputs` / `outputs`).

---

## Flake outputs

```nix
outputs = { nixpkgs, self, ... }: {
  lib                 = import ./lib/functions { inherit flake; };
  nixosModules        = rec { snowglobe-lib; nixos; jovian; nixos-hardware; default = snowglobe-lib; };
  nixosConfigurations = import ./nixosConfigurations { inherit flake; };
  overlays            = import ./overlays { inherit flake; };
  packages            = perSystem ./packages;
  devShells           = perSystem ./devshell.nix;
};
```

### `lib`

The public function library (`import ./lib/functions { inherit flake; }`), merging two sets:

- **`flake-helpers`** — `mkNixosHost`, the host builder. See **[host-builder.md](host-builder.md)**.
- **`module-wrappers`** — the override-weight helpers plus `mkProgramOption`, `installProgram`, `mkGraphicalService`, `mkProgramAlias`. See **[authoring.md](authoring.md)**.

Consumers reach these as `snowglobe-lib.lib.<name>`.

### `nixosModules`

A `rec` set, so members can reference each other:

| Attr | Definition | Notes |
|---|---|---|
| `snowglobe-lib` | An `{ imports = [ … ]; }` aggregate (see below) | The full framework — what consumers import. |
| `nixos` | `import-tree ./nixosModules/nixos` | Program modules, services, upstream patches, `keyring`, `substituters`. Imported transitively by `snowglobe-lib`; also exposed standalone. |
| `jovian` | `import ./nixosModules/jovian { inherit flake; }` | Steam Deck config. **Not** in the default set — opt-in. |
| `nixos-hardware` | `inputs.nixos-hardware.nixosModules` | Re-exported raw (nixos-hardware doesn't wrap its modules in options). |
| `default` | `= snowglobe-lib` | The flake's default NixOS module. |

### `nixosConfigurations`

Reference hosts, all built via `mkNixosHost`: four installer ISO variants (`snowglobe-installer-x86_64`, `-untrusted`, `-small`, `-small-untrusted`) and the `testmonkey` CI host. See **[cli.md](cli.md)**.

### `overlays`

A `rec` set: `packages` (alias `default`) composes the custom `./packages`, the `./package-patches`, and extra `vimPlugins`; plus `nix-post-build-hook-queue` and `flux` re-exported from inputs. All overlay values are applied everywhere — `perSystem` builds `pkgs` with them, and the `snowglobe-lib` module sets `nixpkgs.overlays = builtins.attrValues outputs.overlays`. See **[packages-and-overlays.md](packages-and-overlays.md)**.

### `packages` and `devShells`

Both use the `perSystem` helper, which evaluates a path once per supported system with an unfree-allowed, fully-overlaid `pkgs`:

```nix
perSystem = src:
  lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
    import src {
      inherit flake;
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = builtins.attrValues outputs.overlays;
      };
    });
```

`packages.<system>` comes from `./packages`; `devShells.<system>.default` from `./devshell.nix` (a shell with `ci.sh` + `snowglobe-rebuild`).

---

## Module composition

The default module set is assembled in `flake.nix`:

```nix
snowglobe-lib = {
  imports = [
    (import-tree [
      ./nixosModules/snowglobe-lib
      { nixpkgs.overlays = builtins.attrValues outputs.overlays; }
      outputs.nixosModules.nixos
      inputs.disko.nixosModules.default
      inputs.nix-post-build-hook-queue.nixosModules.default
      inputs.nix-index-database.nixosModules.default
    ])
    # secrets storage and key management
    # does not work with import-tree for some reason
    inputs.sops-nix.nixosModules.default
  ];
};
```

So importing `nixosModules.default` (which `mkNixosHost` does for you) pulls in:

- `./nixosModules/snowglobe-lib` — the framework's own modules (the `enable` gate, GPU/desktop/boot config, profiles, the big `programs.*` defaults block).
- An inline module applying all framework overlays.
- `nixosModules.nixos` — the program-module tree, services, `keyring`, `substituters`, and upstream patches.
- The `disko`, `nix-post-build-hook-queue`, and `nix-index-database` modules.
- `sops-nix`.

> **Gotcha:** `sops-nix.nixosModules.default` is added **outside** the `import-tree` call, with the comment *"does not work with import-tree for some reason."* If you add sops-nix-style modules, append them directly to `imports`, not via the tree.

---

## `import-tree`

[`import-tree`](https://github.com/vic/import-tree) (`vic/import-tree`) takes a list of paths and recursively discovers every `.nix` file under each directory, importing them all as NixOS modules. This is how snowglobe-lib avoids a hand-maintained `imports = [ … ]` list — dropping a `.nix` file under `nixosModules/snowglobe-lib/` or `nixosModules/nixos/programs/<name>/` wires it in automatically.

It also powers `mkNixosHost`'s `configDir`: a consumer's host directory is `import-tree`d so every `.nix` file under it merges into the host.

> `import-tree` skips any path containing `/_`, though nothing in this repo currently relies on that.

---

## The `snowglobe-lib.enable` gate

`nixosModules/snowglobe-lib/default.nix` defines a single master switch and wraps essentially the entire default configuration behind it:

```nix
options.snowglobe-lib.enable = lib.mkEnableOption "Snowglobe-Lib's default NixOS configuration";
config = lib.mkIf config.snowglobe-lib.enable { … };
```

Importing the module does **nothing** until `snowglobe-lib.enable = true` (which `mkNixosHost` sets for you, at `setDefault` priority). For the full inventory of what flips on, see **[options.md](options.md#what-snowglobe-libenable-applies)**.

---

## The override-weight ladder

Defined in `lib/functions/module-wrappers/default.nix`. In the NixOS module system, `lib.mkOverride <prio> v` sets a value's priority where **a lower number wins**. Reference points: `mkForce` = 50, an unannotated definition = 100, `mkDefault` = 1000, `mkOptionDefault` = 1500.

```nix
setDefault             = object: lib.mkOverride 1337 object;
overrideDefault        = object: lib.mkOverride 1336 object;
overrideNixpkgsDefault = object: lib.mkOverride 899  object;
```

```
50    mkForce                  ← consumer hard override — always wins
100   plain assignment         ← consumer normal config — wins over everything below
899   overrideNixpkgsDefault   ← framework, beats nixpkgs mkDefault
1000  mkDefault                ← consumer soft default / nixpkgs default
1336  overrideDefault          ← framework, overrides its own setDefault
1337  setDefault               ← framework, the weakest default in the stack
```

| Helper | Weight | Wins against | Loses to | Purpose |
|---|---|---|---|---|
| `setDefault` | 1337 | nothing weaker | everything above | The standard soft default — used for almost every framework value. Your plain assignment or even `mkDefault` silently overrides it. |
| `overrideDefault` | 1336 | `setDefault` | `mkDefault` and stronger | Lets one framework module override another's `setDefault`, while still yielding to you. |
| `overrideNixpkgsDefault` | 899 | `mkDefault`, `setDefault`, `overrideDefault` | plain (100), `mkForce` | For options nixpkgs itself pins with `mkDefault` (e.g. `environment.binsh`, `users.defaultUserShell`). `setDefault` (1337) would *lose* to nixpkgs's `mkDefault` (1000), so the framework drops below 1000 to win — while staying above 100 so your plain assignment still wins. |

### Why this matters

The entire `snowglobe-lib.enable` block is opinionated, but it's meant to be **freely overridable**. By setting defaults at `1337`/`1336` (weaker than `mkDefault`'s `1000`), a consumer overrides *any* framework default with an ordinary assignment — no "conflicting definitions" error. `overrideNixpkgsDefault` (`899`) handles the special case where nixpkgs already claimed `1000`. Net effect: you get a fully-configured system that behaves like suggestions, never locks.

**To override a framework default:** just assign the option normally.

```nix
# the desktop base sets services.polkit-gnome.enable via setDefault true;
# this plain assignment (priority 100) wins with no conflict:
services.polkit-gnome.enable = false;
```

The only values you'll need `mkForce` for are the framework's *hard* settings (plain `true`/`false`, not run through a helper) — these are rare and called out in [options.md](options.md) and [desktops.md](desktops.md).

---

## The `jovian` module

`nixosModules/jovian/default.nix` (opt-in, imported via `outputs.nixosModules.jovian`) imports `jovian-nixos`'s module and defaults `jovian.steam.{enable,autoStart}` and `jovian.decky-loader.enable` to `true` (via `setDefault`). It hard-sets `services.displayManager.ly.enable = false` (Jovian enables SDDM) and installs a user activation script enabling Decky's CEF remote-debugging flag. It is **not** part of the default set — add it to a host's `modules`/`specialArgs` deliberately.

---

## Disabled upstream modules

`nixosModules/nixos/disabled.nix` removes several stock nixpkgs modules via `disabledModules` so the framework can replace them:

```nix
disabledModules = [
  "programs/neovim.nix"          # replaced by the framework's own neovim module
  "programs/wayland/waybar.nix"  # "forces a service unit and is not very flexible"
  "programs/foot"
  "programs/nm-applet"
];
```

> **Consequence:** `programs.neovim.*`, `programs.waybar.*`, `programs.foot.*`, and the nm-applet options seen elsewhere come from snowglobe-lib's **replacement** modules (see [programs.md](programs.md)), not upstream nixpkgs.

---

See also: **[options.md](options.md)** for the option tree the `enable` gate applies, and **[authoring.md](authoring.md)** for the `lib` helpers that build it all.
