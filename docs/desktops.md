# Desktops & GPU

snowglobe-lib splits the desktop/GPU surface into three layers:

1. **GPU wiring** — `snowglobe-lib.system.gpu-vendors` auto-enables per-vendor GPU modules.
2. **The shared desktop base** ([`snowglobe-lib.desktop`](options.md#snowglobe-libdesktop)) — portals, audio, Bluetooth, greeter, fonts, flatpak, and optional Wayland tooling. Turned on automatically by any desktop module.
3. **Per-WM desktop modules** ([`snowglobe-lib.desktop.<wm>`](#desktop-modules)) — pick a compositor; it flips the base on and installs that WM's default apps.

> All values are `setDefault` (overridable) unless flagged **plain**/**hard**/`mkForce`/`overrideDefault`. See [architecture.md](architecture.md#the-override-weight-ladder).

- [Desktop modules](#desktop-modules)
- [GPU](#gpu)

---

## Desktop modules

Pick **one** in your host config:

```nix
snowglobe-lib.desktop.niri.enable = true;
```

Every WM module forces `snowglobe-lib.system.hasDesktop = lib.mkForce true` (which disables the [headless debloater](options.md#snowglobe-libheadless-debloater) and enables `nvidia-settings`) and turns on the [shared base](options.md#snowglobe-libdesktop).

| Module | Option | `installWaylandDeps` | Session | Greeter |
|---|---|---|---|---|
| [Hyprland](#hyprland) | `snowglobe-lib.desktop.hyprland.enable` | `true` | UWSM | `ly` |
| [Niri](#niri) | `snowglobe-lib.desktop.niri.enable` | `true` | niri native | `ly` |
| [labwc](#labwc) | `snowglobe-lib.desktop.labwc.enable` | `true` | UWSM | `ly` |
| [KDE Plasma 6](#kde-plasma-6) | `snowglobe-lib.desktop.kde.enable` | **`false`** | Plasma | **SDDM** |

> Multiple DIY WMs (niri/hyprland/labwc) can be enabled together — they'll all flip the base on and stack their default apps. KDE is mutually exclusive (see below).

### Hyprland

`snowglobe-lib.desktop.hyprland.enable` — "Snowglobe-lib's default hyprland configuration."

- `programs.hyprland.enable = true`; `programs.hyprland.withUWSM = setDefault true` (UWSM starts `graphical-session.target`).
- Default apps (`setDefault`): `kitty` (terminal), `dolphin` (files), `hyprlauncher` (menu), `hyprlock` (lock).
- `programs.swaylock.enable = overrideDefault false` — turns off the base's swaylock in favor of hyprlock.

### Niri

`snowglobe-lib.desktop.niri.enable` — "Snowglobe-Lib's niri configuration."

- `programs.niri.enable = true` (no UWSM toggle).
- Default apps (`setDefault`): `alacritty` (terminal), `fuzzel` (picker), `xwayland-satellite` (XWayland).
- `programs.waybar.enable = setDefault true` with `waybar.systemd.enable = setDefault false` — prevents two waybars from niri's default config.
- `programs.pwvucontrol` (when pipewire is on): `enable` + `pavucontrolAlias = setDefault true` — because waybar's default config hardcodes `pavucontrol`.

### labwc

`snowglobe-lib.desktop.labwc.enable` — "Snowglobe-Lib's labwc module."

- `programs.labwc.enable = true`; `programs.labwc.withUWSM = setDefault true`.
- Default apps (`setDefault`): `foot` (terminal), `rofi` (launcher).
- Uniquely sets `snowglobe-lib.desktop.enable = lib.mkForce true` (others use plain `true`).

### KDE Plasma 6

`snowglobe-lib.desktop.kde.enable` — "Snowglobe-Lib's KDE plasma module."

- **Mutually exclusive** with DIY desktops: an assertion fails if `niri`, `hyprland`, or `labwc` is also enabled (*"You cannot use other snowglobe-lib.desktop modules in conjunction with KDE."* — KDE is too invasive).
- Sets the base with **`installWaylandDeps = false`** (KDE brings its own Wayland tooling).
- `services.desktopManager.plasma6.enable = true`.
- **Greeter swap:** `ly` off (hard), `sddm` on.
- **Debloat:** excludes `khelpcenter`, `kinfocenter`.
- **Qt → Plasma:** `qt.platformTheme` / `qt.style` set to `null` (weight 899) so Plasma manages Qt independent of Nix.
- **Polkit:** disables soteria and polkit-gnome in favor of KDE's agent.
- **Disables base apps that duplicate Plasma** (`overrideDefault false`): `blueman`, `pwvucontrol`, `swaync`, `batsignal`, `mousepad`, `gnome-software` (use Discover), `nautilus` (use Dolphin), `networkmanagerapplet`, `nwg-look`, `selectdefaultapplication`.

> **KDE icon-repair gotcha:** a `system.userActivationScripts.fix-plasma-icons` runs `sed` over `~/.config/plasma-org.kde.plasma.desktop-appletsrc` and `~/Desktop/*` to rewrite stale `/nix/store/<hash>-system-path/share/applications` references back to `/run/current-system/sw/share/applications` — Plasma pins icons to store paths that vanish after a flake update. (Affects users not using home-manager.)

---

## GPU

You **don't** enable GPU modules by hand — set the vendor list and the framework derives them (under `snowglobe-lib.enable`):

```nix
# usually via mkNixosHost { gpu-vendors = [ "amd" "intel" ]; }
snowglobe-lib.system.gpu-vendors = [ "amd" "intel" ];
# ⇒ snowglobe-lib.gpu.amd.enable   = true
#   snowglobe-lib.gpu.intel.enable = true
#   snowglobe-lib.gpu.nvidia.enable = builtins.elem "nvidia" […] (false here)
```

The list is `str`-typed (not an enum), so a typo silently enables nothing.

### Common (`gpu/common.nix`)

When **any** GPU module is on: `hardware.graphics.enable = true` (hard), and `services.lact.enable` (`setDefault`) follows `hardware-tools.enable || gaming.enable` (`lact` is a GPU monitor/control daemon).

### AMD (`gpu/amd.nix`)

| Setting | Value |
|---|---|
| `services.xserver.videoDrivers` | `[ "amdgpu" ]` (hard) |
| `hardware.amdgpu.overdrive.enable` | `setDefault true` (overclocking) |
| `hardware.amdgpu.initrd.enable` | `mkDefault true` (full-res early KMS) |

### Intel (`gpu/intel.nix`)

Adds `intel-media-driver` and `intel-vaapi-driver` to `hardware.graphics.extraPackages` (VA-API hardware video acceleration). No options.

### NVIDIA (`gpu/nvidia.nix`)

| Setting | Value | Notes |
|---|---|---|
| `services.xserver.videoDrivers` | `[ "nvidia" ]` | hard |
| `hardware.nvidia.modesetting.enable` | `setDefault true` | |
| `hardware.nvidia.powerManagement.enable` | `setDefault true` | |
| `hardware.nvidia.open` | `setDefault true` | **open kernel modules** — RTX 20-series or newer only |
| `hardware.nvidia.nvidiaSettings` | `setDefault true`, gated on `desktop.enable` | the `nvidia-settings` menu |
| `hardware.nvidia.package` | `setDefault …nvidiaPackages.beta` | **beta** driver branch |

> **NVIDIA defaults assume modern hardware.** For pre-Turing cards, override `hardware.nvidia.open = false` and pick a different `hardware.nvidia.package` (e.g. `.production` or a legacy branch). Both are `setDefault`, so a plain assignment wins — no `mkForce` needed.

---

See also: **[options.md](options.md#snowglobe-libdesktop)** for the full shared-desktop-base inventory · **[programs.md](programs.md)** for the apps each desktop installs.
