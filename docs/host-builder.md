# Host builder — `mkNixosHost`

`snowglobe-lib.lib.mkNixosHost` (`lib/functions/flake-helpers/mkNixosHost.nix`) is a thin, opinionated wrapper around `nixpkgs.lib.nixosSystem`. It turns a few hardware facts into a complete, framework-enabled host. Every argument has a default, so `mkNixosHost { }` builds a valid (generic) host.

```nix
nixosConfigurations.myhost = snowglobe-lib.lib.mkNixosHost {
  hostname     = "myhost";
  firmware     = "UEFI";
  cpu-vendor   = "amd";
  gpu-vendors  = [ "nvidia" ];
  isVM         = false;
  stateVersion = "26.05";
  system       = "x86_64-linux";
  configDir    = ./hosts/myhost;
  modules      = [ ./hosts/myhost/hardware-configuration.nix ];
  specialArgs  = { inherit inputs; };
};
```

## Arguments

| Argument | Type / values | Default | Meaning |
|---|---|---|---|
| `hostname` | string | `"nixos"` | System name → `networking.hostName`. |
| `firmware` | `"UEFI"` \| `"BIOS"` | `"UEFI"` | Firmware implementation → `snowglobe-lib.system.firmware`. Drives the GRUB EFI/BIOS choice in [`boot-config`](options.md#snowglobe-libboot-config). |
| `cpu-vendor` | `"intel"` \| `"amd"` \| `null` | `null` | CPU vendor (microcode, CPU-specific kernel modules) → `snowglobe-lib.system.cpu-vendor`. |
| `gpu-vendors` | list of `"intel"` / `"nvidia"` / `"amd"` | `[ ]` | GPU vendors present → `snowglobe-lib.system.gpu-vendors`; each enables the matching [GPU module](desktops.md#gpu). |
| `isVM` | bool | `false` | Whether the host is a QEMU VM → `snowglobe-lib.system.isVM` (skips redistributable firmware). |
| `stateVersion` | string | `"26.11"` | NixOS release first installed → `system.stateVersion`. |
| `system` | string | `"x86_64-linux"` | Target architecture → passed to `nixosSystem` and set as `nixpkgs.hostPlatform`. |
| `modules` | list of modules | `[ ]` | Your extra NixOS modules, appended **last** (so they can override). |
| `specialArgs` | attrset | `{ }` | Forwarded verbatim to `nixosSystem`'s `specialArgs`. |
| `configDir` | path \| `null` | `null` | Host config directory, `import-tree`'d if it exists (see below). |

## What it assembles

In `modules` order:

1. **`outputs.nixosModules.default`** — the whole `snowglobe-lib` module tree.
2. **An inline module** that sets:
   - `snowglobe-lib.enable = slib.setDefault true;` — turns the framework on at the weakest priority (overridable).
   - `nixpkgs.hostPlatform = system;`
   - `system.stateVersion = stateVersion;`
   - `networking.hostName = hostname;`
   - `snowglobe-lib.system = { inherit cpu-vendor gpu-vendors isVM firmware; };`
   - `sops.defaultSopsFile = lib.mkIf configDirExists (slib.setDefault "${configDir}/secrets.yaml");` — only when `configDir` exists.
3. **`hostConfig`** — `inputs.import-tree configDir` if `configDir != null` **and** `builtins.pathExists configDir`; otherwise `{ }`.
4. **`++ modules`** — your extra modules.

## `configDir` behavior

`configDir` is gated by **both** `!= null` **and** `builtins.pathExists`:

- If it **exists**, every `.nix` file under it is `import-tree`'d and merged into the host, **and** `sops.defaultSopsFile` defaults to `${configDir}/secrets.yaml` (at `setDefault` priority — overridable).
- If you pass a path that **doesn't exist**, you silently get an empty config and **no** `sops.defaultSopsFile` (no error).
- If you **omit** `configDir`, neither happens — you point `sops.defaultSopsFile` at your secrets yourself.

This is the convention the [installer](cli.md#snowglobe-installsh--end-to-end-installer-flow) scaffolds: one directory per host holding `configuration.nix`, `hardware-configuration.nix`, `disko.nix`, `users/`, and `secrets.yaml`.

## `specialArgs` and `inputs`

`mkNixosHost` does **not** inject `inputs` into your modules. If any module you pass references `inputs` (or `outputs`), supply it yourself:

```nix
specialArgs = { inherit inputs; };
```

The reference consumer does exactly this. The reference installer-scaffolded host also passes `specialArgs = { inherit inputs; }; modules = [ outputs.nixosModules.default ];`.

## Notes on defaults

The builder's argument defaults differ slightly from the underlying `snowglobe-lib.system.*` option defaults (defined in `nixosModules/snowglobe-lib/system.nix`):

| | builder default | option default |
|---|---|---|
| `cpu-vendor` | `null` | `""` |
| `firmware` | `"UEFI"` | `null` |
| `gpu-vendors` | `[ ]` | `[ ]` |
| `isVM` | `false` | `false` |

The `cpu-vendor` empty-string vs `null` distinction matters for [`libvirtd-qemu`](options.md#snowglobe-liblibvirtd-qemu), which gates a `kvm-${cpu-vendor}` kernel module on `cpu-vendor != null`. Always set a real `cpu-vendor` when using KVM. See [known-issues.md](known-issues.md).

---

See also: **[getting-started.md](getting-started.md)** for the surrounding flake, and **[options.md](options.md)** for the options the host-facts feed.
