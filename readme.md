This flake contains my personal NixOS modules, nix package derivations, nix functions, and NixOS installation environment + script.

This project aims to provide a one-stop-shop for any project that I create or use regularly with NixOS to make them easily accessible in one place.

It is actively maintained and is currently in use by several friends and family members.

If you are interested in NixOS, Consider checking it out.

------------------------------------------------------------------------

# Getting Started

Supported Architectures:
- x86_64-linux
- aarch64-linux (limited package support)

There are a few methods for consuming the modules, depending on your preferences.

# 1. Raw addition to a flake

First, add the input:

```
{
  inputs = { 
    gman.url = "https://git.earthgman.dev/earthgman/nix-modules";
  };
}
```
This project is also mirrored to codeberg, allowing you to use that url in case my personal git server is down for any reason.

Unfortunately nixpkgs has an issue with consuming nix modules that extend the nixpkgs.lib attrSet.
This is because the `lib` argument commonly seen in configuration.nix is hardcoded to be nixpkgs.lib by the nixosSystem function.
As a result, an extended lib requires calling nixosSystem with a special argument to provide the extended attrSet to all submodules of your configuration.

```
{
  inputs = { 
    gman.url = "https://git.earthgman.dev/earthgman/nix-modules";
  };
}

outputs = { gman, ... }@inputs: 
let
  # merged attrset of nixpkgs.lib and custom lib functions needed for modules to work properly.
  lib = gman.lib;
in
{
  nixosConfigurations."your-configuration" = lib.nixosSystem {
    # Integrate custom lib functions with your nixos hosts.
    specialArgs = { inherit lib; };
    modules = [
      ./configuration.nix

      # add the module set
      gman.nixosModules.default
    ];
  };
}
```

If you do not wish to use any custom modules from nixosModules/mixins then you are good to go.
However, Some custom suites and patches found under nixosModules/mixins may not be fully functional unless you populate various metadata referenced by the option `config.meta` found at nixosModules/core/meta.nix

There are 2 methods:
- 1. Do it manually, fill in the various information in a module consumed by your host (such as configuration.nix)
- 2. Use a custom wrapper for lib.nixosSystem `mkHost`.

# 2. nixosSystem wrapper function

A wrapper function `mkHost` for nixosSystem can be used in your flake.nix to automatically propagate the needed modules to your host configuration.
It also provides a great overview of the host's specific properties.

```
{
  inputs = {
    gman.url = "https://git.earthgman.dev/earthgman/nix-modules";
  };
}

outputs = { gman, ... }@inputs: 
let
  # merged attrset of nixpkgs.lib and custom lib functions needed for modules to work properly.
  lib = gman.lib;
in
{
  # each argument is described in detail at /lib/mkHost.nix
  nixosConfigurations."your-configuration" = lib.mkHost {
    hostname = "nixos";
    cpu = "amd";
    gpu = "amd";
    specialization = "gaming";
    desktop = "niri";
    system = "x86_64-linux";
    stateVersion = "25.11";
    configDir = ./nixos;
    extraSpecialArgs = { inherit inputs; };
    secretsFile = ./nixos/secrets.yaml;
    extraModules = [ outputs.nixosModules.default ]
  };
}
```

Now all modules should be fully functional.

# 3. Installation script

This project also provides a guided installation for those who have never used NixOS and want to give it a try.
While the official installers from nixos.org are typically enough to get started, they lack several features such as declarative disk partition management and declarative secret management.

This custom installer aims to integrate these features into the installation process, providing a truly declarative, flake-powered NixOS configuration repository you can easily expand to your own needs.

Currently the following desktop environments are supported:
- KDE Plasma 6
- Niri
- Hyprland

To obtain the installer, go to https://cache.earthgman.dev/binaries and download the nixos-installer.iso for your system's CPU architecture.

Note: There is an alternate version of the installer suffixed with -small. This build of the installer lacks firmware blobs from linux-firmware and can be used if your hardware does not require any blobs from it.
If in doubt, just use the default image.

If you wish to validate integrity and non-repudiation of the downloaded image, decrypt the sha256.gpg associated with it. My gpg public key is stored on the webroot.

If you do not feel comfortable putting an iso image from a random guy on the internet into your computer, you can [build it yourself](https://git.earthgman.dev/earthgman/nix-modules/src/branch/dev/docs/Build-Installer.md).

Once booted, the rest should be self-explanitory.

I encourage you to report issues if you have any.
