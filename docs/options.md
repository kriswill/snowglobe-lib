# Options reference

The `snowglobe-lib.*` option tree, the defaults `snowglobe-lib.enable` applies, the supporting modules, and the two cross-cutting helpers (`substituters`, `keyring`).

> Most defaults below are set with the override-weight helpers (`setDefault` = `mkOverride 1337`, `overrideDefault` = `1336`, `overrideNixpkgsDefault` = `899`). **Anything set with a helper is a freely-overridable soft default** — assign the option normally to change it. Values noted as **plain** / **hard** are set without a helper and need `lib.mkForce` to override. See [architecture.md](architecture.md#the-override-weight-ladder).

- [`snowglobe-lib.enable`](#snowglobe-libenable)
- [What `enable` applies](#what-snowglobe-libenable-applies)
- [`snowglobe-lib.system`](#snowglobe-libsystem)
- [`snowglobe-lib.desktop`](#snowglobe-libdesktop)
- [`snowglobe-lib.boot-config`](#snowglobe-libboot-config)
- [`snowglobe-lib.dynamic-timezone`](#snowglobe-libdynamic-timezone)
- [`snowglobe-lib.headless-debloater`](#snowglobe-libheadless-debloater)
- [`snowglobe-lib.libvirtd-qemu`](#snowglobe-liblibvirtd-qemu)
- [`hacks.nix`](#hacks)
- [`substituters`](#substituters)
- [`keyring`](#keyring)

For desktops, GPU, profiles, and program modules see [desktops.md](desktops.md), [profiles.md](profiles.md), and [programs.md](programs.md).

---

## `snowglobe-lib.enable`

```nix
options.snowglobe-lib.enable = lib.mkEnableOption "Snowglobe-Lib's default NixOS configuration";
```

The master switch (default **off**). Everything in `nixosModules/snowglobe-lib/default.nix` and `hacks.nix` is wrapped in `lib.mkIf config.snowglobe-lib.enable`. [`mkNixosHost`](host-builder.md) sets it `setDefault true` for you.

---

## What `snowglobe-lib.enable` applies

### Nix / store / nixpkgs

| Option | Value | Helper |
|---|---|---|
| `nix.package` | `pkgs.lix` | `setDefault` |
| `nix.channel.enable` | `false` | `setDefault` |
| `nix.settings.fallback` | `true` | `setDefault` |
| `nix.settings.experimental-features` | `[ "nix-command" "flakes" ]` | plain (appended) |
| `nix.settings.auto-optimise-store` | `true` | `setDefault` |
| `nixpkgs.config.allowUnfree` | `true` | `setDefault` |
| `documentation.nixos.enable` | `false` | `setDefault` |

### Boot / kernel / firmware

| Option | Value | Helper |
|---|---|---|
| `boot.kernelPackages` | `pkgs.linuxPackages_latest` | `setDefault` |
| `boot.tmp.cleanOnBoot` | `true` | `setDefault` |
| `boot.loader.efi.canTouchEfiVariables` | `true` | `setDefault` |
| `hardware.enableRedistributableFirmware` | `!system.isVM` | `setDefault` |

### Networking / shells / console

| Option | Value | Helper | Notes |
|---|---|---|---|
| `networking.networkmanager.enable` | `true` | `setDefault` | |
| `services.openssh.enable` | `true` | `setDefault` | |
| `users.defaultUserShell` | `programs.zsh.package` | `overrideNixpkgsDefault` | zsh as login shell (beats nixpkgs' bash default). |
| `environment.binsh` | `${pkgs.dash}/bin/dash` | `overrideNixpkgsDefault` | `/bin/sh` → dash. |
| `console.useXkbConfig` | `true` | `setDefault` | TTYs follow the X keymap chosen at install. |
| `environment.sessionVariables.SYSTEMD_KEYMAP_DIRECTORIES` | `${pkgs.kbd}/share/keymaps` | `setDefault` | works around a nixpkgs gap. |

### sops

| Option | Value | Helper |
|---|---|---|
| `sops.defaultSopsFormat` | `"yaml"` | `setDefault` |
| `sops.age.keyFile` | `/root/.config/sops/age/keys.txt` | `setDefault` |

### Always-installed packages

`environment.systemPackages` always gets `sops`, `age`, and terminfo for popular terminals (`kitty`, `alacritty`, `foot`, `ghostty`, `wezterm`, `st`) so SSH sessions render cleanly.

### Program defaults

All `setDefault`. **Enable** toggles:

`neovim` (+ `viAlias`, `vimAlias = !programs.vim.enable`), `bat`, `eza`, `fzf`, `ripgrep`, `yazi`, `jq`, `btop`, `fastfetch`, `file`, `tmux`, `zip`, `ncdu`, `sysz`, `busybox`, `brightnessctl`, `git` (+ `lazygit` follows git), `zsh` (+ `autosuggestions`, `syntaxHighlighting`), `disko`, `snowglobe-rebuild`, and `nh` (with `flake = "/etc/nixos"` and periodic `clean`). `vim.enable` defaults `false`.

**Package swaps** (degoogled/hardened choices — these set `*.package` only, they don't enable the program):

| Option | Value |
|---|---|
| `programs.firefox.package` | `pkgs.librewolf` |
| `programs.chromium.package` | `pkgs.ungoogled-chromium` |
| `programs.discord.package` | `pkgs.vesktop` |
| `programs.libreoffice.package` | `pkgs.libreoffice-fresh` |
| `programs.password-store.package` | `pass` + `pass-otp` |
| `programs.obs-studio.enableVirtualCamera` | `true` |

### Derived toggles

| Toggle | Default expression | Helper |
|---|---|---|
| `snowglobe-lib.gpu.{amd,intel,nvidia}.enable` | `builtins.elem "<vendor>" system.gpu-vendors` | plain |
| `snowglobe-lib.dynamic-timezone.enable` | `networkmanager.enable && time.timeZone == null` | `setDefault` |
| `snowglobe-lib.boot-config.enable` | `true` | `setDefault` |
| `snowglobe-lib.headless-debloater.enable` | `!system.hasDesktop` | `setDefault` |
| `substituters."nix-store.earthgman.dev"` | enabled, priority 100 | `setDefault` |

---

## `snowglobe-lib.system`

Descriptive host facts (set by [`mkNixosHost`](host-builder.md)) that other modules read. Options only — no `config`.

| Option | Type | Default | Purpose |
|---|---|---|---|
| `snowglobe-lib.system.cpu-vendor` | string or `null` | `""` | CPU vendor (microcode, `kvm-<vendor>`). |
| `snowglobe-lib.system.gpu-vendors` | list of str | `[ ]` | GPU vendors present; drives [GPU module](desktops.md#gpu) enablement. |
| `snowglobe-lib.system.isVM` | bool | `false` | QEMU VM? (skips redistributable firmware). |
| `snowglobe-lib.system.hasDesktop` | bool | `false` | Has a desktop? Forced `true` by every desktop module; its inverse drives the headless debloater. |
| `snowglobe-lib.system.firmware` | string or `null` | `null` | `"UEFI"` or `"BIOS"`; checked by `boot-config`. |

> **Gotcha — types are effectively free-form strings.** `cpu-vendor` and `firmware` use `oneOf [ str "amd" str "intel" ]`-style declarations where the literals are invalid type entries (they should be `enum`); because `str` is also present, the net effect is "any string." A typo in `gpu-vendors` (e.g. `"nvida"`) silently enables nothing. See [known-issues.md](known-issues.md).

---

## `snowglobe-lib.desktop`

The **shared desktop base**, enabled automatically by any [desktop module](desktops.md). You normally don't set these directly — you pick a WM and it flips `desktop.enable` on.

| Option | Type | Default |
|---|---|---|
| `snowglobe-lib.desktop.enable` | enable | off |
| `snowglobe-lib.desktop.installWaylandDeps` | enable | off |

### `desktop.enable = true` — always-on

- **Display / security:** `services.displayManager.ly.enable` (`setDefault`); `security.polkit.enable` (**hard** `true`); `services.polkit-gnome.enable` (`setDefault`).
- **Audio:** `security.rtkit.enable`, `services.pipewire.{enable, alsa.enable, alsa.support32Bit, pulse.enable, jack.enable}` (all `setDefault`).
- **Bluetooth:** `hardware.bluetooth.enable` (`setDefault`); `services.blueman.enable` follows it.
- **Networking:** appends the `networkmanager-openvpn` plugin; `programs.networkmanagerapplet.enable` (`setDefault`).
- **Flatpak:** `services.flatpak.enable` (`setDefault`); `programs.gnome-software.enable` as frontend. *(No Flathub remote is registered — add it yourself.)*
- **Default GUI apps** (`setDefault`): `firefox`, `nautilus`, `mousepad`, `gnome-calculator`, `nwg-look`, `dconf` (+ `dconf-editor`), `notify-send`, `selectdefaultapplication`, `batsignal` (+ systemd unit), `pwvucontrol` (when pulse is on), `xdg-user-dirs`, `xdg-utils`.
- **Fonts/icons:** adds `adwaita-icon-theme`, `noto-fonts`, `nerd-fonts.meslo-lg`.
- **XDG portals:** `xdg.portal.{enable, xdgOpenUsePortal}` (`setDefault`); portals `xdg-desktop-portal-gtk`, `xdg-desktop-portal-termfilechooser`.
- **Graphics:** `hardware.graphics.enable` (**hard**); `enable32Bit` (`setDefault`, x86 only).

### `installWaylandDeps = true` — additional

- `xdg.portal.wlr.enable`; tools `grim`, `slurp`, `wl-clipboard`, `wlr-randr`; `swaync` (+ systemd unit); `swaylock` — all `setDefault`.
- Session vars (`setDefault`): `NIXOS_OZONE_WL = "1"` (Electron → Wayland), `_JAVA_AWT_WM_NONREPARENTING = "1"` (fix blank Java/XWayland screens).

> TODOs in the code: a commented-out Flathub-remote service, a commented-out `security.soteria.enable` (broken under UWSM 26), and "detect if bluetooth hardware exists." See [known-issues.md](known-issues.md).

---

## `snowglobe-lib.boot-config`

```nix
options.snowglobe-lib.boot-config.enable = lib.mkEnableOption "Snowglobe-Lib's grub configuration";
```

Default-enabled by core. Configures **GRUB** (reads `isUEFI = system.firmware == "UEFI"`):

| Option | Value | Helper |
|---|---|---|
| `boot.loader.timeout` | `10` | `setDefault` |
| `boot.loader.grub.enable` | `true` | plain |
| `boot.loader.grub.efiSupport` | `isUEFI` | plain |
| `boot.loader.grub.devices` | `[ "nodev" ]` | plain |
| `boot.loader.grub.gfxmodeEfi` / `gfxmodeBios` | `"1920x1080"` | `setDefault` |
| `boot.loader.grub.theme` | `pkgs.nixos-grub-theme` | `setDefault` |
| `boot.loader.grub.extraEntries` | Reboot + Poweroff (+ "UEFI Firmware Settings" when UEFI) | plain |

> **Gotcha:** hardcoded to GRUB (not systemd-boot). If `firmware` is `null` you get a BIOS-style GRUB install.

---

## `snowglobe-lib.dynamic-timezone`

```nix
options.snowglobe-lib.dynamic-timezone = {
  enable = lib.mkEnableOption "geolocation based time synchronization";
  server = lib.mkOption { type = lib.types.str; default = "https://ipapi.co/timezone"; };
};
```

Default-enabled by core **only when** NetworkManager is on and `time.timeZone == null`. Installs a NetworkManager dispatcher script (`10-update-timezone`) that, on `connectivity-change`, runs `timedatectl set-timezone "$(curl --fail <server>)"`.

It emits `config.warnings` if NetworkManager is off, or if `time.timeZone` is set (which it requires to be `null`).

> **Gotcha:** reaches out to an external API (`ipapi.co`) on each connectivity change. Set a static `time.timeZone` *or* use this — not both.

---

## `snowglobe-lib.headless-debloater`

```nix
options.snowglobe-lib.headless-debloater.enable = lib.mkEnableOption "Snowglobe-Lib's nixos debloater for headless systems";
```

Default-enabled by core when `!system.hasDesktop`. Strips desktop bloat: empties `environment.defaultPackages`, sets `BROWSER=echo`, turns off all `xdg.*` autostart/icons/menus/mime/sounds, all `documentation.*`, `fonts.fontconfig`, `command-not-found`, swaps `git` → `gitMinimal`, and forces `hardware.enableRedistributableFirmware = false`.

> **Priority note:** this module uses plain `lib.mkDefault` (and one `mkOverride 899`), i.e. *higher* priority than the `setDefault`s elsewhere — that's how it overrides them on headless hosts.

---

## `snowglobe-lib.libvirtd-qemu`

```nix
options.snowglobe-lib.libvirtd-qemu.enable = lib.mkEnableOption "Snowglobe-Lib's libvirtd-qemu configuration";
```

**Opt-in** (not auto-enabled). When on: installs `dnsmasq`, trusts `virbr0` in the firewall, enables `virtualisation.libvirtd` with `swtpm`, `qemu_kvm`, and `virtiofsd`, enables `spiceUSBRedirection`, and adds a `kvm-${cpu-vendor}` kernel module when `cpu-vendor != null`. When a desktop is present, also enables `programs.virt-manager` (`setDefault`).

> **Gotcha:** the `kvm-*` module is gated on `cpu-vendor != null`, but `system.cpu-vendor`'s default is `""` (not `null`) — so by default a `kvm-` module with an empty suffix is added. Set `snowglobe-lib.system.cpu-vendor = "amd"`/`"intel"` for working KVM. See [known-issues.md](known-issues.md).

---

## hacks

`nixosModules/snowglobe-lib/hacks.nix` has no options of its own; it is applied under `snowglobe-lib.enable`. Workarounds you should know about:

- **labwc session target:** if `programs.labwc.enable`, adds the labwc package to `systemd.packages` (provides `labwc-session.target`).
- **ly + systemd services:** when `ly` is the greeter, sets `systemd.services.display-manager.environment.XDG_CURRENT_DESKTOP = "X-NIXOS-SYSTEMD-AWARE"` (works around [fairyglade/ly#706](https://codeberg.org/fairyglade/ly/issues/706), which otherwise blocks services from starting on login).
- **soteria teardown:** when `security.soteria.enable`, makes the `polkit-soteria` user service `Requisite` `graphical-session.target` so it tears down properly on non-UWSM sessions (e.g. Niri).

---

## `substituters`

`nixosModules/nixos/substituters.nix` adds a higher-level `substituters` option — an easier way to register/toggle trusted binary caches than editing `nix.settings` directly.

```nix
substituters.<host> = {
  enable    = true;     # mkEnableOption — trust this cache
  protocol  = "https";  # URL scheme (https, s3, …)
  publicKey = "<host>:<key>=";
  priority  = 40;       # lower = higher priority
};
```

| Option | Type | Default |
|---|---|---|
| `enable` | bool | `false` |
| `protocol` | str | `"https"` |
| `publicKey` | str | `""` |
| `priority` | int | `40` |

For each enabled entry it appends `"${protocol}://${host}?priority=${priority}"` to `nix.settings.substituters` and the key to `trusted-public-keys`. **Assertion:** enabling a cache with an empty `publicKey` fails the build.

### The default cache

`snowglobe-lib.enable` registers one cache out of the box:

```nix
substituters."nix-store.earthgman.dev" = {
  enable    = slib.setDefault true;
  publicKey = "nix-store.earthgman.dev:2Qrw9kS+K2c00ikcgaz5Y0M7j5XmkhFJz3d7oNgJdLw=";
  priority  = slib.setDefault 100;   # below cache.nixos.org
};
```

This is a **maintainer-run server** caching the framework's patched packages. Disable it per-host with `substituters."nix-store.earthgman.dev".enable = false;` (what the `-untrusted` installer does).

> The installer's `-untrusted` path writes an opt-out for `nix-store.homelab.earthgman.dev` — a **different** name than the cache the default module enables. See [known-issues.md](known-issues.md#cache-name-mismatch).

---

## `keyring`

`nixosModules/nixos/keyring.nix` — a single place to store **public** keys by name, for reuse across a config. Options only (no `config`); a typed, named registry that consuming modules read.

```nix
options.keyring = {
  ssh     = lib.mkOption { type = attrsOf str; default = { }; };  # public ssh keys
  openpgp = lib.mkOption { type = attrsOf str; default = { }; };  # openpgp public keys
  age     = lib.mkOption { type = attrsOf str; default = { }; };  # age public keys
};
```

Define once, reference by name:

```nix
keyring.ssh.laptop = "ssh-ed25519 AAAA… you@host";
# …elsewhere:
users.users.you.openssh.authorizedKeys.keys = with config.keyring.ssh; [ laptop ];
```

The [installer](cli.md) maintains `keyring.age` and `keyring.ssh` for you and reuses them across reinstalls.

---

See also: **[desktops.md](desktops.md)** · **[profiles.md](profiles.md)** · **[programs.md](programs.md)** · **[architecture.md](architecture.md)**.
