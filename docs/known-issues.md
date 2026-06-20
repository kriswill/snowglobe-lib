# Known issues & gotchas

A consolidated list of footguns, in-code TODOs, and rough edges found across snowglobe-lib, with where they live and how they bite. None of these block normal use, but they're worth knowing before you rely on the framework.

## Bugs / inconsistencies

### Cache-name mismatch

The default module enables the binary cache **`nix-store.earthgman.dev`** (`nixosModules/snowglobe-lib/default.nix`). But the installer's `-untrusted` path writes an opt-out for **`nix-store.homelab.earthgman.dev`** (`lib/scripts/snowglobe-install.sh`, the `CACHE_UNTRUSTED` branch) — a different hostname. So the untrusted installer's generated opt-out line targets a cache name the default module never enabled; the actual `nix-store.earthgman.dev` cache may still be trusted on an "untrusted" install. To be sure, set `substituters."nix-store.earthgman.dev".enable = false;` yourself. See [options.md](options.md#substituters).

### Inert `systemd.programArgs`

`programs.awww`, `programs.batsignal`, and `programs.swayidle` each declare a `systemd.programArgs` option, but it is **never forwarded** to `mkGraphicalService` — setting it has no effect on the generated `ExecStart`. If you need extra args on those services, override the unit's `ExecStart` directly. See [programs.md](programs.md#programs-with-optional-systemd-user-services).

### `libvirtd-qemu` KVM module with empty vendor

`snowglobe-lib.libvirtd-qemu` gates its `kvm-${cpu-vendor}` kernel module on `cpu-vendor != null`, but `snowglobe-lib.system.cpu-vendor` **defaults to `""`** (empty string), not `null`. So by default a malformed `kvm-` module (empty suffix) is added. Always set `snowglobe-lib.system.cpu-vendor = "amd"`/`"intel"` (the [`mkNixosHost`](host-builder.md) arg does this). See [options.md](options.md#snowglobe-liblibvirtd-qemu).

### Effectively free-form `system` types

`snowglobe-lib.system.cpu-vendor` and `firmware` are declared with `oneOf [ str "<literal>" … ]` where the bare string literals are not valid type entries (they should be `lib.types.enum`). Because `lib.types.str` is also present, the net type is just "any string" — so typos aren't caught. Likewise `gpu-vendors` is `listOf str` (not an enum): a misspelled vendor (e.g. `"nvida"`) silently enables nothing. See [options.md](options.md#snowglobe-libsystem).

### `polkit-gnome` unit name typo

The GNOME polkit agent service is named `polkit-gnome-autentication-agent-1` (missing the "h" in "authentication"). Reference it exactly when overriding. See [programs.md](programs.md#services).

## Security-relevant defaults

- **Third-party binary cache trusted by default.** `snowglobe-lib.enable` trusts `nix-store.earthgman.dev` (a maintainer-run server) at priority 100. Disable per-host if you don't want it. See [options.md](options.md#substituters).
- **`stoat-desktop` permits an insecure Electron.** Enabling `programs.stoat-desktop` adds `electron-38.8.4` to `nixpkgs.config.permittedInsecurePackages` **globally** (carries a `# TODO remove me later`). This relaxes the insecure-package guard for your whole config.
- **`dynamic-timezone` calls an external API.** When active it hits `ipapi.co` on each connectivity change to geolocate your timezone. Set a static `time.timeZone` to disable. See [options.md](options.md#snowglobe-libdynamic-timezone).
- **`harden` is all-or-nothing on SSH.** It hard-disables SSH password auth and sets `users.mutableUsers = false` — configure SSH keys and declarative passwords first, or you can lock yourself out. See [profiles.md](profiles.md#harden).
- **Profiles open firewall ports.** `gaming` (Steam local transfers) and `office` (`avahi` mDNS) open ports as a side effect of enabling them.

## Installer limitations

- **Disks need a by-id serial.** The installer rewrites the disko device to `/dev/disk/by-id/<serial>` for persistence; disks without one (common in qemu/kvm) error out. Assign a disk serial in the VM config.
- **No ZFS / bcachefs.** The installer's `boot.supportedFilesystems` is force-set and excludes ZFS and bcachefs (`#TODO figure out how to use zfs`). You can't format them with the default installer.
- **Interactive only.** `snowglobe-rebuild switch`/`boot` prompt for a commit message and push to your remote — don't use them in non-interactive/CI contexts.

## Packaging fragility

- **`vimPlugins.vim-fern`** is pinned to the `main` **branch** with a fixed hash (`packages/vimPlugins/default.nix`). The hash will drift from `main` over time and break the fixed-output fetch — repin to a commit. See [packages-and-overlays.md](packages-and-overlays.md#extra-vim-plugins).
- **FreeTube patch filenames are crossed.** `freetube-build-script.patch` and `freetube-targets.patch` don't match their content (the `@electron-version@` token lives in the build-script patch, applied via `replaceVars`). Re-verify when bumping FreeTube.
- **`labwc-meson-build.patch` is dead.** Present in `overlays/package-patches/` but referenced by nothing; labwc's session target is handled in `hacks.nix` instead.

## Dead / planned code

- **`nixosModules/snowglobe-lib/overlays.nix` is entirely commented out.** It would have added a `snowglobe-lib.overlays.*` option tree (per-overlay `enable` toggles for rolling-release `*-git` overlays + a `zsh-syntax-highlighting-fix`). There are **no live `snowglobe-lib.overlays.*` options** despite the file's presence — don't rely on them.

## In-code TODOs worth tracking

| Where | TODO |
|---|---|
| `default.nix` (dynamic-timezone) | *"I dont think I did this right. very hacky but works. look into ntp."* |
| `desktop.nix` | Commented-out `security.soteria.enable` (broken under UWSM 26); commented-out Flathub-remote service ("redo this"); "detect if bluetooth hardware exists." |
| `gpu/nvidia.nix` | Detect old cards for which `open` modules / the beta driver don't work. |
| `hacks.nix` | *"check up on this file every once in awhile."* |
| `snowglobe-install.sh` | "support some more desktops"; "figure out how to use zfs". |
| `ci.sh` | "allow arbitrary branches"; "build custom packages and package overlays". |

---

Found another? These are the rough edges as of the current `unstable` branch — verify against the code before acting on any of them.
