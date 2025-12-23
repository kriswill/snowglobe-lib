This flake contains my personal NixOS modules, nix package derivations, nix functions, and NixOS installation environment + script.

This project aims to provide various module wrappers and patches for NixOS aimed toward my use case, but is usable by others without being invasive. Think if it as a `nixpkgs+`

It is actively maintained and is currently in use by several friends and family members.

If you are interested in NixOS, Consider checking it out.

------------------------------------------------------------------------

# Getting Started

Supported Architectures:
- x86_64-linux - yes (fully supported)
- aarch64-linux - no (support planned)
- riscv-linux - no

# Add to an independent flake

First, add the input:

```
{
  inputs = { 
    gman.url = "https://codeberg.org/earthgman/nix-modules";
  };
}
```

Unfortunately nixpkgs has an issue with consuming nix modules that extend the nixpkgs.lib attrSet.
This is becuase the `lib` argument commonly seen in configuration.nix is hardcoded to be nixpkgs.lib by the nixosSystem function.
As a result, an extended lib requires calling nixosSystem with a special argument to provide the extended attrSet to all submodules of your configuration.

```
{
  inputs = { 
    gman.url = "https://codeberg.org/earthgman/nix-modules";
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
  };
}
```

You will now have access to my custom nix modules.
These range from patches to many extra options for enabling programs and services.

For a list of custom patches and suites, see nixosModules/mixins
For extra programs and services, see nixosModules/core/programs and nixosModules/core/services

# Installation script

This project also provides a guided installation for those who have never used NixOS and want to give it a try.
While the official installers from nixos.org are typically enough to get started, they lack several features such as declarative disk partition management and declarative secret management.

This custom installer aims to integrate these features into the installation process, providing a truly declarative, flake-powered NixOS configuration repository you can easily expand to your own needs.

Currently the following desktop environments are supported:
- KDE Plasma 6
- Niri
- Sway
- Hyprland

To obtain the installer, go to https://cache.earthgman.dev/binaries and download the nixos-installer-$arch.iso.
If you wish to test the integrity and non-repudiation. Download the installer.sha256.gpg. My gpg public key is stored on the webroot.

If you do not feel comfortable putting an iso image from a random guy on the internet into your computer, you can [build it yourself](https://codeberg.org/earthgman/nix-modules/src/branch/dev/docs/Build-Installer.md).

Once booted, the rest should be self-explanitory.

I encourage you to report issues if you have any.
