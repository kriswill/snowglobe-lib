# Program modules

snowglobe-lib wraps **150+ programs** as NixOS modules under `nixosModules/nixos/programs/<name>/default.nix`. Almost all share one uniform schema built from two helpers, so installing anything looks the same and is per-user-aware.

- [The standard schema](#the-standard-schema)
- [How installation works](#how-installation-works)
- [Non-standard modules](#non-standard-modules)
- [Programs with optional systemd user services](#programs-with-optional-systemd-user-services)
- [Package name ≠ option name](#package-name--option-name)
- [The full catalog](#the-full-catalog)
- [Services](#services)

To author a new one, see **[authoring.md](authoring.md#a-new-program-module)**.

---

## The standard schema

Each module calls `slib.mkProgramOption` for its options and `slib.installProgram` for its config (see [authoring.md](authoring.md)). Unless a module excludes some via `excludedOptions`, every `programs.<name>` gets:

| Option | Type | Default | Effect |
|---|---|---|---|
| `enable` | bool | `false` | Master toggle for the module. |
| `package` | package | the program's nixpkgs package | Freely swappable. |
| `installGlobally` | bool | **`true`** | Adds `package` to `environment.systemPackages` (all users). |
| `installForUsers` | list of str | `[ ]` | Installs per-user via `users.users.<u>.packages`. |
| `userPackages` | attrsOf package | `{ }` | Per-user *custom* package builds (username → package). |

```nix
# install ripgrep for everyone (default behavior):
programs.ripgrep.enable = true;

# install obsidian only for two users, not system-wide:
programs.obsidian = {
  enable = true;
  installGlobally = false;
  installForUsers = [ "alice" "bob" ];
};
```

---

## How installation works

`installProgram` wires the options up:

- `installGlobally = true` → package into `environment.systemPackages`.
- `installForUsers` → each listed user gets the package in `users.users.<u>.packages` (at priority `mkOverride 1350`).
- `userPackages` → per-user custom builds merged into the same place.

> **Assertion:** enabling a program with `installGlobally = false` **and** `installForUsers = [ ]` fails the build:
> *"programs.&lt;name&gt; is enabled but neither has installGlobally nor installForUsers set. You must set one of the options."*
> Since `installGlobally` defaults `true`, this only bites if you explicitly turn it off without giving `installForUsers`.

---

## Non-standard modules

A handful of modules deviate from the standard schema or add behavior. Know these before relying on them:

| Module | What's different |
|---|---|
| `chromium` | `excludedOptions = [ "enable" ]` — reuses nixpkgs' own `programs.chromium.enable`; only layers on the install schema. |
| `kdeconnect` | `excludedOptions = [ "enable" "package" ]` — extends nixpkgs' module. Adds `trayApplet.enable` (a `kdeconnect-indicator` graphical user service). |
| `tmux`, `yazi` | `excludedOptions = [ "enable" "package" ]` — reuse nixpkgs' `enable`/`package`, add the snowglobe deployment options. |
| `zsh` | `excludedOptions = [ "enable" ]`. Adds `pkgs.zsh-syntax-highlighting` / `zsh-autosuggestions` when the matching nixpkgs sub-option is on. |
| `labwc` | **Not** built on the framework. Extends nixpkgs' `programs.labwc`; adds only `withUWSM` (registers a UWSM Wayland session). |
| `starship` | **Not** built on the framework. No options of its own — just installs `cfg.package` when `programs.starship.enable` (from nixpkgs) is set. |
| `yash` | **Not** built on the framework. Hand-rolled `enable`/`package`; registers itself in `environment.shells`. No `installGlobally`/`installForUsers`. |
| `neovim` | `package` defaults to plain `pkgs.neovim` (point it at your own packaged config). Adds `viAlias` / `vimAlias` (build alias packages). |
| `neomutt` | Adds `muttAlias` (default **`true`** → a `mutt` command). Force-enables `mutt-wizard` via `setDefault`. |
| `mutt-wizard` | Heavyweight: transitively enables `password-store`, `abook`, `lynx`, and `services.cron` (as **hard `true`**), pulls in a full mail toolchain, links `/share/mutt-wizard`. |
| `nautilus` | Enables `services.gvfs` (`setDefault`) for network-share mounting. |
| `networkmanagerapplet` | Always creates an `nm-applet` graphical user service when enabled; injects the package into `environment.profiles` so tray icons render on standalone WMs. |
| `pwvucontrol` | Adds `pavucontrolAlias` (default `false`) → a `pavucontrol` → `pwvucontrol` alias. |
| `password-store` | Auto-enables `pass-git-helper` to follow `programs.git.enable` (`setDefault`). |
| `prismlauncher` | Hard-enables `programs.java.enable = true` (avoids re-prompting for Java on every update). |
| `foot` | `systemd.enable` (default **`true`**) registers the `foot --server` unit. |
| `cutentr` | Opens `networking.firewall.allowedUDPPorts = [ 8001 ]` (3DS streaming) — no separate toggle. |
| `dolphin-emu` | Adds `services.udev.packages = [ cfg.package ]` (controller rules). |
| `stoat-desktop` | Globally permits the insecure `electron-38.8.4` (`# TODO remove me later`). See [known-issues.md](known-issues.md). |

KDE-suite modules resolve their package from `pkgs.kdePackages` rather than top-level `pkgs`: `discover`, `dolphin`, `gwenview`, `kalk`, `kdenlive`.

---

## Programs with optional systemd user services

These add a `systemd.enable` option that, when set, defines a `systemd.user.services.<name>` via [`mkGraphicalService`](authoring.md#mkgraphicalservice) (bound to `graphical-session.target`):

| Module | Notes |
|---|---|
| `awww` | `waylandDependent` (only runs under Wayland). |
| `batsignal` | `Restart = "no"`; not Wayland-bound. |
| `kanshi` | `waylandDependent`. |
| `swayidle` | `waylandDependent`. |
| `swaync` | `waylandDependent`, `-daemon` description. |
| `syncthingtray` | Binds to `syncthing.service` (not `graphical-session.target`), runs with `--wait`. |
| `waybar` | `waylandDependent`. |
| `networkmanagerapplet` | Always on when the program is enabled (no separate toggle); runs `nm-applet`. |
| `kdeconnect` | via `trayApplet.enable` → `kdeconnect-indicator`. |

> **Known bug:** `awww`, `batsignal`, and `swayidle` declare a `systemd.programArgs` option that is **never wired into the service** — setting it has no effect. See [known-issues.md](known-issues.md).

---

## Package name ≠ option name

The `package` default differs from the option name for:

| `programs.<name>` | package |
|---|---|
| `gcolor` | `gcolor3` |
| `glabels` | `glabels-qt` |
| `moonlight` | `moonlight-qt` |
| `notify-send` | `libnotify` |
| `swaync` | `swaynotificationcenter` |
| `syncthingtray` | `syncthingtray-minimal` |
| `zint` | `zint-qt` |
| `password-store` | `pass` |
| `discover`, `dolphin`, `gwenview`, `kalk`, `kdenlive` | `kdePackages.*` |

---

## The full catalog

All 152 program modules (each is `programs.<name>`). Names marked **†** have non-standard behavior — see [Non-standard modules](#non-standard-modules) or [systemd services](#programs-with-optional-systemd-user-services) above.

**Terminals & shells:** `alacritty`, `foot`†, `ghostty`, `kitty`, `st`, `yash`†, `zsh`†

**CLI / TUI utilities:** `btop`, `eza`, `fzf`, `jq`, `ncdu`, `ripgrep`, `sysz`, `yazi`†, `busybox`, `fastfetch`, `file`, `gh`, `hstr`, `nvd`, `starship`†, `tmux`†, `yt-dlp`, `zip`

**Editors & notes:** `neovim`†, `obsidian`, `gnome-text-editor`, `mousepad`, `xournalpp`

**Mail / chat / XMPP:** `gajim`, `neomutt`†, `mutt-wizard`†, `abook`, `discord`

**Web browsers:** `chromium`†, `qutebrowser`, `freetube`, `lynx`, `tor-browser`

**File managers:** `nautilus`†, `dolphin` (kde), `yazi`†

**Wayland desktop bits:** `awww`†, `batsignal`†, `brightnessctl`, `fuzzel`, `hyprlauncher`, `kanshi`†, `rofi`, `slurp`, `grim`, `sunsetr`, `swayidle`†, `swaylock`, `swaync`†, `switcheroo`, `waybar`†, `wl-clipboard`, `wlopm`, `wlr-randr`, `nwg-look`, `xwayland-satellite`, `labwc`†

**Networking / remote:** `networkmanagerapplet`†, `openconnect`, `remmina`, `filezilla`, `kdeconnect`†, `syncthingtray`†

**Audio / music / DAW:** `ardour`, `audacity`, `cava`, `musescore`, `puddletag`, `pwvucontrol`†, `rmpc`

**Graphics / video / creative:** `blender`, `gimp`, `krita`, `gcolor`, `gthumb`, `gwenview` (kde), `kdenlive` (kde), `video-trimmer`, `vlc`, `mpv`, `simple-scan`, `glabels`, `zint`

**Gaming / emulation:** `lutris`, `mangohud`, `protonup-qt`, `steam-rom-manager`, `steamtinkerlaunch`, `bottles`, `prismlauncher`†, `mrpack-install`, `mcrcon`, `r2modman`, `moonlight`, `xivlauncher`, `xclicker`, `cemu`, `dolphin-emu`†, `dosbox`, `flips`, `ryubing`, `cutentr`†, `supertux`, `supertuxkart`

**Security / pentest:** `binsider`, `john`, `metasploit`, `nmap`, `zenmap`, `kernel-hardening-checker`

**Hardware / monitoring:** `keymapp`, `kdiskmark`, `openboardview`, `phoronix-test-suite`, `piper`, `s-tui`

**Office / finance:** `libreoffice`, `gnucash`, `ledger-live-desktop`, `gnome-calculator`, `kalk` (kde), `gnome-clocks`, `calcure`

**System / GNOME apps:** `gnome-software`, `gnome-system-monitor`, `discover` (kde), `dconf-editor`, `selectdefaultapplication`, `xdg-user-dirs`, `xdg-utils`, `notify-send`, `bustle`

**Secrets / pass:** `password-store`†, `qtpass`, `pass-git-helper`

**Nix / system mgmt:** `disko`, `nix-fast-build`, `nix-output-monitor`, `snowglobe-rebuild`

**Media discovery / fun:** `ani-cli`, `manga-tui`, `cbonsai`, `cmatrix`, `pipes`, `sl`, `stoat-desktop`†

> This list groups the catalog for readability; the authoritative source is the directory listing of `nixosModules/nixos/programs/`. A few entries appear under the most useful heading even where they could fit several.

---

## Services

Two service modules live under `nixosModules/nixos/services/`:

- **`services.keyd`** — companion to nixpkgs' `services.keyd`; just installs the `keyd` CLI alongside the upstream service (no options of its own).
- **`services.polkit-gnome`** — `services.polkit-gnome.enable` defines a `polkit-gnome-autentication-agent-1` graphical user service (the GNOME polkit agent). *Note: the unit attribute name is misspelled "autentication" — reference it exactly when overriding.*

---

See also: **[authoring.md](authoring.md)** to add a module · **[options.md](options.md)** for which programs the core/desktop modules enable by default.
