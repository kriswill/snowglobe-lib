# snowglobe-lib documentation

Reference docs for the **snowglobe-lib** NixOS framework. New here? Start with the [project README](../README.md) for the high-level pitch, then come back for detail.

## Reading order

If you're **consuming** snowglobe-lib in your own config:

1. **[getting-started.md](getting-started.md)** — install from the ISO, or pin it as a flake input and realize a host.
2. **[host-builder.md](host-builder.md)** — the `mkNixosHost` argument reference.
3. **[options.md](options.md)** — what `snowglobe-lib.enable` gives you, and the `snowglobe-lib.*` option tree.
4. **[profiles.md](profiles.md)** / **[desktops.md](desktops.md)** / **[programs.md](programs.md)** — the features you switch on.

If you're **extending or hacking on** snowglobe-lib:

1. **[architecture.md](architecture.md)** — how the flake, modules, and override-weights fit together.
2. **[authoring.md](authoring.md)** — add a program module, graphical service, package, overlay, or cache.
3. **[packages-and-overlays.md](packages-and-overlays.md)** and **[cli.md](cli.md)** — the package set, the installer, and CI.
4. **[known-issues.md](known-issues.md)** — the rough edges and in-code TODOs.

## All docs

| Doc | Covers |
|---|---|
| [getting-started.md](getting-started.md) | Two on-ramps (ISO install, flake input) + day-2 rebuilds. |
| [architecture.md](architecture.md) | Flake inputs/outputs, module composition, `import-tree`, the `enable` gate, the override-weight ladder. |
| [host-builder.md](host-builder.md) | `mkNixosHost` full reference; `configDir`/secrets behavior. |
| [options.md](options.md) | `snowglobe-lib.*` options, the core defaults, supporting modules, substituters, keyring. |
| [profiles.md](profiles.md) | `gaming` / `office` / `hacker-mode` / `harden` / `nix-tools` / `hardware-tools`. |
| [desktops.md](desktops.md) | `niri` / `hyprland` / `labwc` / `kde` desktop modules and the `amd`/`intel`/`nvidia` GPU modules. |
| [programs.md](programs.md) | The program-module framework + the full catalog of 150+ programs. |
| [authoring.md](authoring.md) | Extending the framework: modules, services, aliases, packages, overlays, caches, disko mixins. |
| [packages-and-overlays.md](packages-and-overlays.md) | Custom packages and in-place package patches. |
| [cli.md](cli.md) | `snowglobe-rebuild`, the installer (`snowglobe-install.sh`), and the maintainer `ci.sh`. |
| [known-issues.md](known-issues.md) | Consolidated gotchas, footguns, and TODOs found in the code. |
