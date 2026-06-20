# Packages & overlays

snowglobe-lib ships a few custom packages and a layered overlay. Everything here is exposed **two ways**:

1. **As flake packages** — `packages.<system>.<name>` for `x86_64-linux` / `aarch64-linux`, buildable directly (`nix build .#omori-font`).
2. **Into `pkgs`** — the same `packages/default.nix` is merged into nixpkgs by the `packages` overlay (aliased `default`), so any config applying snowglobe-lib's overlays gets them as plain `pkgs.<name>`.

- [Overlay structure](#overlay-structure)
- [Custom packages](#custom-packages)
- [Extra vim plugins](#extra-vim-plugins)
- [Package patches](#package-patches)

---

## Overlay structure

`overlays/default.nix` (`{ flake }: rec { … }`) exports:

| Overlay | Source | Purpose |
|---|---|---|
| `packages` | local | Custom packages + package-patches + extra vimPlugins. |
| `default` | = `packages` | Canonical alias. |
| `nix-post-build-hook-queue` | input | Re-exported. |
| `flux` | input | Re-exported. **Required** by `corekeeper-dedicated-server` — provides the `mkSteamServer`/`fetchSteam` builders (not in nixpkgs). |

The `packages` overlay composes three pieces:

```nix
final: prev:
  import ../packages { pkgs = final; }                                  # custom packages
  // import ./package-patches { inherit final prev; nixpkgs-stable = …; } # in-place patches
  // { vimPlugins = prev.vimPlugins // import ../packages/vimPlugins { pkgs = final; }; }
```

`vimPlugins` is merged *onto* `prev.vimPlugins` (added, not replacing). `nixpkgs-stable` (pinned `nixos-26.05`) is wired in for patches that need a stable-channel package — the plumbing is present though nothing currently uses it.

---

## Custom packages

Defined in `packages/default.nix` (plus `snowglobe-rebuild` merged in):

| `pkgs.<name>` / flake package | What it is |
|---|---|
| `nixos-grub-theme` | A GRUB theme (AdisonCavani's `distro-grub-themes`, v3.2). Accepts an optional `themeConfig.background` to swap the wallpaper. Used by [`boot-config`](options.md#snowglobe-libboot-config). |
| `omori-font` | The OMORI TTF, fetched from `earthgman.dev`. |
| `_8-bit-operator-font` | The "8-bit Operator" font (note the leading underscore in the attr). |
| `star-pixel-icons` | Starciad's pixel GTK icon theme. |
| `corekeeper-dedicated-server` | Core Keeper dedicated server (Steam appId `1963720`), built via the `flux` overlay's `mkSteamServer`. **Requires the `flux` overlay in scope.** |
| `snowglobe-rebuild` | The `nixos-rebuild` wrapper CLI (see [cli.md](cli.md#snowglobe-rebuild)). |
| `snowglobe-rebuild-unwrapped` | The raw script with no `PATH` guarantees. |

All package builders are pure (`stdenvNoCC.mkDerivation`, fixed-output fetchers); none use the override-weight helpers.

---

## Extra vim plugins

`packages/vimPlugins/default.nix` — three plugins not in nixpkgs, merged into `pkgs.vimPlugins`:

- `vimPlugins.nvim-vague` — the `vague.nvim` colorscheme.
- `vimPlugins.shellcheck-nvim`.
- `vimPlugins.vim-fern`.

> **Gotcha:** `vim-fern` is pinned to `rev = "main"` (a branch, not a commit) with a fixed hash — the hash will eventually drift from `main` and break the fetch. See [known-issues.md](known-issues.md).

---

## Package patches

`overlays/package-patches/default.nix` overrides nixpkgs packages in place, so consuming `pkgs.<name>` gets the patched version (these are why the [binary cache](options.md#substituters) exists):

| Package | What / why |
|---|---|
| `freetube` | Bumped to **0.24.1** with its own `yarnOfflineCache`; two patches force an unpacked `dir` build and use the Nix-provided Electron. |
| `ani-cli` | Bumped to **4.14.1** ("ani-cli cant download media from version in nixpkgs"). |
| `puddletag` | `postFixup` moves a misplaced icon into `hicolor/256x256/apps/` so menus show it. |
| `zsh-syntax-highlighting` | Rewritten `installPhase` that fixes dangling highlighter symlinks. |
| `btop` | Built with `rocmSupport = true; cudaSupport = true;` for GPU monitoring. |

### Patch files

- `freetube-build-script.patch` — switches electron-builder targets to `dir` (the unpacked build the Nix derivation needs).
- `freetube-targets.patch` — injects the Nix Electron version/dist so it isn't downloaded.
- `labwc-meson-build.patch` — would fix where labwc installs its systemd user unit, **but is not referenced by any `.nix` file** — currently dead. (labwc's session target is handled in [`hacks.nix`](options.md#hacks) instead.)

> The two FreeTube `.patch` filenames are crossed relative to their content (the `@electron-version@` token lives in `freetube-build-script.patch`, applied via `replaceVars`). Re-verify the mapping if you bump FreeTube. See [known-issues.md](known-issues.md).

---

See also: **[authoring.md](authoring.md#a-custom-package)** to add your own · **[architecture.md](architecture.md#overlays)** for how overlays are applied.
