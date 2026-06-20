# Authoring & extending

How to add to snowglobe-lib (or build on its `lib` from your own flake): new program modules, graphical services, command aliases, packages, overlays, binary caches, and disko layouts.

The building blocks are the `module-wrappers` half of the [`lib`](architecture.md#lib) output. Inside the repo, import them directly:

```nix
let slib = import ../../../../lib/functions/module-wrappers { inherit lib; }; in …
```

(They only need `lib`, so any plain `{ lib, ... }` module can use them. The `flake-helpers` half — `mkNixosHost` — needs the full flake.)

- [A new program module](#a-new-program-module)
- [`mkProgramOption`](#mkprogramoption)
- [`installProgram`](#installprogram)
- [`mkGraphicalService`](#mkgraphicalservice)
- [`mkProgramAlias`](#mkprogramalias)
- [The override-weight helpers](#the-override-weight-helpers)
- [A custom package](#a-custom-package)
- [An overlay](#an-overlay)
- [A binary cache](#a-binary-cache)
- [Disko mixins](#disko-mixins)

---

## A new program module

The canonical skeleton is `lib/templates/program-module.nix`. Copy it to `nixosModules/nixos/programs/<name>/default.nix` (where [`import-tree`](architecture.md#import-tree) auto-discovers it), fill in `programName`/`description`:

```nix
{ pkgs, lib, config, ... }:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "mytool";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    inherit pkgs;
    programName = programName;
    packageName = programName;   # omit/adjust if the pkgs attr differs
    description = "a short description";
  };

  config = lib.mkIf cfg.enable (slib.installProgram { inherit programName config; });
}
```

That gives `programs.mytool.{enable,package,installGlobally,installForUsers,userPackages}` for free. The `../../../../` import depth is correct for `nixosModules/nixos/programs/<name>/default.nix`; adjust if you place it elsewhere.

To do more than install (systemd unit, aliases, extra options), pass `extraOptions`/`excludedOptions` to `mkProgramOption` and `extraModules` to `installProgram` — see the examples below and the [non-standard modules](programs.md#non-standard-modules) in the catalog.

---

## `mkProgramOption`

`lib/functions/module-wrappers/mkProgramOption.nix`. Returns an attrset of options to drop under `options.programs.<name>`.

| Arg | Default | Meaning |
|---|---|---|
| `pkgs` | — (required) | For `mkPackageOption`. |
| `programName` | — (required) | Option namespace and label. |
| `packageName` | `programName` | The `pkgs` attr for the `package` option. |
| `description` | `null` | Appended to the enable description (`programName + ", a " + description`). **Always pass one** — see gotcha. |
| `excludedOptions` | `[ ]` | Option names to **not** generate (to patch a module nixpkgs already defines). |
| `extraPackageArgs` | `{ }` | Extra args for `mkPackageOption`. |
| `extraOptions` | `{ }` | Extra options merged in last. |

Generated options: `enable`, `package`, `installGlobally` (default `true`), `installForUsers` (default `[ ]`), `userPackages` (always). Each of the first four is skipped if listed in `excludedOptions`.

> **Gotcha:** if `description` is `null`, the enable description concatenates a `null` and breaks. Always pass a `description`.

### Adding extra options

```nix
options.programs.waybar = slib.mkProgramOption {
  inherit pkgs;
  programName = "waybar";
  description = "a wayland bar";
  extraOptions = {
    systemd.enable = lib.mkEnableOption "waybar as a systemd user service";
  };
};
```

### Patching a nixpkgs module

Use `excludedOptions` to reuse the upstream `enable`/`package` and only add the deployment options (as `tmux`/`yazi`/`zsh` do):

```nix
options.programs.tmux = slib.mkProgramOption {
  inherit pkgs;
  programName = "tmux";
  description = "a terminal multiplexer";
  excludedOptions = [ "enable" "package" ];   # come from nixpkgs
};
```

---

## `installProgram`

`lib/functions/module-wrappers/installProgram.nix`. Turns the options above into installs. Wrap it in `lib.mkIf cfg.enable`.

| Arg | Default | Meaning |
|---|---|---|
| `programName` | — | Which `programs.<name>` to install. |
| `config` | — | The module `config`. |
| `extraModules` | `{ }` | Extra config merged in (systemd units, aliases, side effects). |

Logic: `installGlobally` → `environment.systemPackages`; `installForUsers` → per-user packages; `userPackages` → per-user custom builds; plus the [no-install assertion](programs.md#how-installation-works).

```nix
config = lib.mkIf cfg.enable (slib.installProgram {
  inherit programName config;
  extraModules = {
    systemd.user.services.waybar = lib.mkIf cfg.systemd.enable (slib.mkGraphicalService {
      serviceName = "waybar";
      package = cfg.package;
      waylandDependent = true;
    });
  };
});
```

---

## `mkGraphicalService`

`lib/functions/module-wrappers/mkGraphicalService.nix`. Returns a systemd **user** service unit bound to `graphical-session.target` (starts/stops with the desktop). Use under `systemd.user.services.<name>`.

| Arg | Default | Meaning |
|---|---|---|
| `serviceName` | — | Unit name / `Description` base. |
| `package` | — | Package providing the binary. |
| `binName` | `serviceName` | Executable under `${package}/bin/`. |
| `programArgs` | `[ ]` | Args appended to `ExecStart`. |
| `waylandDependent` | `false` | Adds `ConditionEnvironment = "WAYLAND_DISPLAY"`. |
| `extraServiceConfig` | `{ }` | Merged into `serviceConfig` (can override). |
| `extraUnitConfig` | `{ }` | Merged into `unitConfig` (can override). |
| `extraDescription` | `""` | Appended to `Description`. |

The unit it produces: `wantedBy`/`After`/`Requisite`/`PartOf` = `graphical-session.target`; `serviceConfig` `Type=exec`, `Restart=on-failure`, `RestartSec=5`, `Slice=app.slice` (all `mkDefault`); a restart limiter (`StartLimitIntervalSec=10`, `StartLimitBurst=2`).

> The `serviceConfig` values are `mkDefault` (override freely). The `unitConfig` values are not — override via `extraUnitConfig` or normal priority. When wiring `programArgs` from an option, **remember to actually forward it** — several modules declare a `systemd.programArgs` option but forget to pass it, leaving it inert (see [known-issues.md](known-issues.md)).

---

## `mkProgramAlias`

`lib/functions/module-wrappers/mkProgramAlias.nix`. Builds a `pkgs.symlinkJoin` that re-exposes a package under an extra binary name.

| Arg | Meaning |
|---|---|
| `program` | Existing binary name. |
| `alias` | New binary name. |
| `package` | Source package. |
| `pkgs` | The package set. |

```nix
# a `mutt` that runs neomutt:
mutt-alias = slib.mkProgramAlias { program = "neomutt"; alias = "mutt"; package = cfg.package; inherit pkgs; };
```

The result is a package — add it like any other (e.g. to a user's `packages` or `environment.systemPackages`).

---

## The override-weight helpers

When your module sets a value you want consumers to be able to override trivially, use these instead of a bare assignment or `mkDefault`. See [architecture.md](architecture.md#the-override-weight-ladder) for the full ladder.

```nix
config.services.gvfs.enable = slib.setDefault true;             # weakest; user's plain assignment wins
config.programs.swaylock.enable = slib.overrideDefault false;   # override another module's setDefault
config.environment.binsh = slib.overrideNixpkgsDefault "${pkgs.dash}/bin/dash";  # beat a nixpkgs mkDefault
```

---

## A custom package

Add a `callPackage`-style derivation under `packages/` and reference it from `packages/default.nix`. It becomes both a flake `packages.<system>.<name>` **and** a `pkgs.<name>` (via the `packages` overlay). See [packages-and-overlays.md](packages-and-overlays.md).

```nix
# packages/default.nix  →  { pkgs, ... }: { mypkg = pkgs.callPackage ./mypkg { }; ... }
```

Extra vim plugins go under `packages/vimPlugins/default.nix` and merge into `pkgs.vimPlugins`.

---

## An overlay

`overlays/default.nix` is `{ flake }: rec { … }`. The `packages` overlay (aliased `default`) composes custom packages + package-patches + vimPlugins. To **patch** a nixpkgs package in place, add an `overrideAttrs`/`override` entry to `overlays/package-patches/default.nix`. To re-export an input's overlay, add `myinput = inputs.myinput.overlays.default;`. All overlay values are applied everywhere automatically.

---

## A binary cache

Use the [`substituters`](options.md#substituters) option rather than editing `nix.settings` directly:

```nix
substituters."cache.example.org" = {
  enable    = true;
  publicKey = "cache.example.org:base64key=";
  priority  = 50;   # lower = higher priority
};
```

(An enabled cache with an empty `publicKey` fails an assertion.)

---

## Disko mixins

`lib/mixins/disko/` holds drop-in `disko.devices` layouts. Both target a single GPT disk with a hybrid BIOS+UEFI boot so the same image boots either firmware:

- **`default-ext4.nix`** — `bios-boot` (EF02, 1M) + `ESP` (EF00, 512M, vfat `/boot`, `umask=0077`) + `root` (100%, ext4, `/`).
- **`default-ext4-luks.nix`** — same boot partitions; root is a LUKS container (`allowDiscards = true`, `passwordFile = "/tmp/luks-password"`, used at format time only) wrapping ext4.

> Both default `device = "/dev/sda"` with a `# CHANGE PATH BEFORE FORMATTING` comment. The [installer](cli.md) rewrites this to a stable `/dev/disk/by-id/<serial>`. If you import a mixin directly, set `disko.devices.disk.nixos.device` yourself before formatting.

---

See also: **[programs.md](programs.md)** for real-world uses of every helper · **[architecture.md](architecture.md)** for how it all composes.
