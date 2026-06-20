# CLI & tooling

The three scripts in `lib/scripts/`: the day-2 rebuild wrapper, the interactive installer, and the maintainer CI script.

- [`snowglobe-rebuild`](#snowglobe-rebuild) — day-to-day rebuilds
- [`snowglobe-install.sh`](#snowglobe-installsh--end-to-end-installer-flow) — the ISO installer
- [Installer ISO configs](#installer-iso-configs)
- [`ci.sh`](#cish--maintainer-only) — maintainer CI / cache publishing

---

## `snowglobe-rebuild`

A POSIX-sh wrapper around `nixos-rebuild` (`lib/scripts/snowglobe-rebuild.sh`) that keeps your flake synced and logged in git. Enabled by default (`programs.snowglobe-rebuild.enable`). Invoke it exactly like `nixos-rebuild`:

```sh
snowglobe-rebuild switch --flake .#myhost
```

### Behavior

- **Subcommands:** `switch`/`boot` set `PERSISTENT` (→ git sync + logging) and need sudo; `test` needs sudo; `repl`/`info`/`rollback` don't. All of `test`/`switch`/`boot`/`repl`/`info`/`rollback` may use `nh os`.
- **Flake dir:** parsed from `--flake` (the `#host` suffix stripped, `readlink -f`'d); defaults to `/etc/nixos`. Errors if there's no `flake.nix` there.
- **Backend:** prefers `nh os` (exports `NH_OS_FLAKE`) when `nh` is on `PATH` and the subcommand allows it; otherwise `sudo nixos-rebuild`; plain `nixos-rebuild` when already root.
- **Git sync** (only if `<flake>/.git` exists): checks the remote; for `PERSISTENT` builds does `stash → pull → stash apply` to sync across a fleet (skips stash if clean), and always `git add .` so Nix sees new files. If the remote is unreachable it offers to continue without sync.
- **`--target-host user@host`:** the part after `@` becomes the label in `updates.log`.
- **Post-switch** (`PERSISTENT` only): appends a record (host, timestamp, generation, kernel) to `<flake>/updates.log`, then **prompts for a commit message**, `git commit`, and `git push`. Uses `notify-send` for success/error when available.

> **Gotcha:** `switch`/`boot` are **interactive** (commit prompt, y/n prompts) and **push to your remote** — not suited to non-interactive/CI use. And like `nixos-rebuild`, `--flake <path>` won't follow a symlinked path; `cd` into the real checkout and use `.#host`.

### Packaging

Two layers (`packages/snowglobe-rebuild/`): `snowglobe-rebuild-unwrapped` is the raw `writeScriptBin`; `snowglobe-rebuild` is a `symlinkJoin` that `wrapProgram`s `gitMinimal` onto `PATH` (its only runtime dep). The latter is what you install. See [packages-and-overlays.md](packages-and-overlays.md).

---

## `snowglobe-install.sh` — end-to-end installer flow

`lib/scripts/snowglobe-install.sh` is an interactive installer run **as root** on the [live ISO](#installer-iso-configs) (bundled there as `install.sh`). It ensures `nix-daemon` is up, checks connectivity (offers `nmtui`), and has three modes.

### Mode C — fresh install (default)

1. **Format disks** — `disko` (default GPT: 1M BIOS-boot + 512M ESP + ext4 root), optional **LUKS**. Custom disko files in `/etc/disko` are offered via `fzf`. The chosen device is rewritten to a stable `/dev/disk/by-id/<serial>`.
2. **Hostname** — sanitized to `[a-zA-Z0-9_-]`.
3. **Hardware detection** — firmware, CPU vendor, VM?, GPU vendors, arch, NixOS version. These become your `mkNixosHost` args.
4. **Locale / keyboard / timezone** — defaults `en_US.UTF-8` / `us` / dynamic.
5. **Desktop** — KDE / Niri / labwc / Hyprland / none.
6. **Profiles** — `hardware-tools`, `gaming` (desktop only), `office` (desktop only), `hacker-mode`, `nix-tools`, `harden` (default **yes**).
7. **Review loop** — edit any choice via `fzf` until satisfied.
8. **Scaffold the flake** — writes a complete `flake.nix` + `nixosModules/default/`, `overlays/`, `packages/`, `devshell.nix` stubs at `/mnt/etc/nixos`.
9. **Keyring** — creates `nixosModules/default/keyring.nix` with empty `keyring.{ssh,age,openpgp}`.
10. **sops setup** — generates (or reuses) an **age** key at `/mnt/root/.config/sops/age/keys.txt`, maintains `.sops.yaml`, writes the public key into the keyring. **Back this private key up.**
11. **Write the host `configuration.nix`** — locale/keyboard, optional timezone, `snowglobe-lib.desktop.<de>.enable`, each `snowglobe-lib.profiles.<p>.enable`.
12. **Register the host** in `nixosConfigurations/default.nix` via `mkNixosHost { … configDir = ./<host>; specialArgs = { inherit inputs; }; modules = [ outputs.nixosModules.default ]; … }`.
13. **Hardware + disko in place** — `nixos-generate-config --no-filesystems`, copies the disko file; injects `zramSwap.enable = true` if RAM ≤ 4 GB.
14. **Users** — username (use `root` to configure root), optional password (hashed into sops), SSH keys (from/to `keyring.ssh`), `wheel`/`networkmanager` groups.
15. **Host SSH keys** — the ISO's host keys are stored into the host's `secrets.yaml` and wired via `sops.secrets`.
16. **Encrypt** secrets, `nixfmt` everything, then **install**.

### Mode A — reinstall an existing config

Clones your repo, picks a host (`fzf`), reuses its `disko.nix`, re-detects hardware and rewrites the `mkNixosHost` args, blocks until your private age key is present, then installs.

### Mode B — append a host to an existing repo

Clones your repo and runs the fresh-install flow, but appends to the existing `nixosConfigurations/default.nix` instead of scaffolding a new flake.

### Install step

`nixos-install --no-channel-copy --flake "/mnt/etc/nixos#<host>"` — with `--no-root-password` if declarative users exist, otherwise it prompts for a root password (not stored in sops). Creates a 4 GB swap file first if RAM is low.

> **Gotchas:** disks need a by-id serial (common failure in qemu/kvm — assign a disk serial in the VM). The installer can't format **ZFS/bcachefs** by default (`#TODO figure out how to use zfs`). See [known-issues.md](known-issues.md).

---

## Installer ISO configs

`nixosConfigurations/default.nix` exports four installer variants and the `testmonkey` CI host. Build an image with:

```sh
nixos-rebuild build-image --image-variant iso-installer --flake .#snowglobe-installer-x86_64
```

| Attribute | Difference |
|---|---|
| `snowglobe-installer-x86_64` | Base. |
| `snowglobe-installer-x86_64-untrusted` | Disables the `earthgman` cache and sets `CACHE_UNTRUSTED=1` (installed system opts out too). |
| `snowglobe-installer-x86_64-small` | `mkForce`s firmware off — smaller image. |
| `snowglobe-installer-x86_64-small-untrusted` | Both. |

The live config (`nixosConfigurations/snowglobe-installer/configuration.nix`) imports the upstream minimal-installation-CD profile, bundles `install.sh` + `nixfmt`/`sops`/`age`, ships the disko defaults and locale list under `/etc/`, and enables `disko`/`gh`/`zsh`. (`boot.supportedFilesystems` is force-set; ZFS/bcachefs are disabled.)

### `testmonkey`

A CI "kitchen-sink" host (`nixosConfigurations/testmonkey/`) that enables **every** program/service module, all GPUs, several desktops, all profiles, libvirtd-qemu, the Jovian module, and all custom packages — so CI can build/cache everything and catch failing nixpkgs builds. Not an installer.

---

## `ci.sh` — maintainer only

`lib/scripts/ci.sh` is an `fzf`-driven menu used by the maintainer to validate the framework and publish installers/caches. **Not part of any consumer workflow.** Menu actions: build `testmonkey`; `nix flake check` / build registered downstream repos (from `.secrets/repo-urls.txt`, with their `snowglobe-lib` input repointed to the current branch); build/sign/upload the installer ISOs; build all packages; and git branch-merge helpers (`current → unstable`, `unstable → main`). It drives the `nix-post-build-hook-queue` uploader to sign and push built paths to `nix-store.earthgman.dev`.

---

See also: **[getting-started.md](getting-started.md)** · **[options.md](options.md#substituters)** for the cache · **[known-issues.md](known-issues.md)**.
