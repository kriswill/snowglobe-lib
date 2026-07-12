# Yet another fleet manager for NixOS

**Similar projects & Inspirations**
- snowfall-lib - https://github.com/snowfallorg/lib
- clan-core - https://github.com/clan-lol/clan-core

**What is this?**

Short Answer - A NixOS configuration / distribution.

Long Answer - Automatic setup tools, NixOS module tweaks, fleet management automation, and preconfigured nix-community projects like disko and sops-nix.
The configuration aims to assist with common difficulties of managing your NixOS configurations.
It aims to be non-invasive, allowing you to freely change the provided flake structure or default settings provided by the modules.

**Why the name?**

Short Answer - Clan was already taken.

Long Answer - In a snowglobe you probably have a little village. In this analogy, the village is your fleet of Nix configurations.
This project serves a factory for manufacturing these configuration environments. They can have one or more houses inside.
Plus, it also fits with a part of my name and the ice/snow/winter theme that many Nix/NixOS projects seem to use.

**Why Use this?**

I've been using NixOS for the past several years, and it is a very powerful Linux distribution.
Unfortunately, there are several gotchas surrounding nix and the nixpkgs ecosystem that give it a rather high barrier to entry to new users.
The process of learning to properly maintain and modularize your NixOS configuration is a very daunting and time consuming task.
Example configurations found in the wild are often very confusing and personalized as there is no concrete way to structure them.

So, I wrote this project as an attempt to solve some of these flaws and construct an example NixOS configuration for you that just works out of the box.
It is currently the daily driver for my personal fleet, which contains both all my workstations and servers, and is highly maintained.
https://codeberg.org/earthgman/dotfiles

**Some noteworthy configuration and features**
- nixpkgs-unstable as the default package source.
- dash as /bin/sh.
- lix instead of cppnix.
- disko instead of fileSystems.
- sops-nix with age for secret management.
- improved default grub theme from https://github.com/AdisonCavani/distro-grub-themes
- ly as the default display manager (except for KDE Plasma)
- default configurations and patches for KDE, Hyprland, Labwc, and Niri
- public keyring moduleset (config.keyring) managed by the installer script (and you).
- optional rebuild wrapper for git synchronization across hosts in your fleet which provides configuration modification logging via nvd (snowglobe-rebuild).
- optional specialization profiles that enable configuration for certain out of the box experiences (gaming, office work, etc).
- many many extra program options for easier application management across your fleet with per-user package scopes.
- package overlays/patches for packages that are not fully functional or dont build at all from nixpkgs-unstable.
- automated installer environment which sets it all up.


# DISCLAIMER

It should go without saying, but this is a passion project that currently has a limited testing scope.
You probably shouldn't use it if you can get fired.


# Getting Started

You can consume the modules directly from an existing nix flake

```nix
{
  inputs = {
    snowglobe-lib.url = "https://codeberg.org/earthgman/snowglobe-lib";
    nixpkgs.follows = "snowglobe-lib/nixpkgs" # recommended but not required
  };

  outputs = { snowglobe-lib, nixpkgs }: 
  {
    nixosConfigurations.myhostname = snowglobe-lib.lib.mkNixosHost {
      hostname = "myhostname";
      system = "x86_64-linux";
      firmware = "UEFI";
      cpu-vendor = "intel";
      gpu-vendors = [ "amd" ];
      isVM = false;
      stateVersion = "26.11";
      specialArgs = { inherit inputs; };
      configDir = ./nixosConfigurations/myhostname;
      modules = [  ];
    };
  };
}
```

This function will take care of the setup and apply the appropriate default configuration for the hardware parameters you pass to it.
You can view every arguments possible value and its description at: lib/functions/flake-helpers/mkNixosHost.nix

**Using the installation images**

Pre-built images can be found at https://www.earthgman.dev/assets/snowglobe-installers/
These contain the scripts responsible for the automatic hardware detection, flake creation, and installation of the distribution.

You can also build these yourself if you have nix installed by using: ```nixos-rebuild build-image```

Images labeled 'small' do not contain extra firmware from linux-firmware. They are useful for VMs or hosts that dont need any blobs from it.
Images labeled 'untrusted' ensure that the provided cache "nix-store.earthgman.dev" is disabled at all times.

Once booted the rest should be self-explanitory.


# Post install

You may wish to change the ownership of /etc/nixos to your underprivledged user so you can edit the config files.
If you do you will need to COPY (not move) /root/.config/sops/age/keys.txt to ~/.config/sops/age/keys.txt to access and modify your secrets.
This file is an unencrypted private key owned by root. Be aware that anyone who gains unauthorized access to your system or drive will have access to it on the filesystem.
You may wish to utilize something like the TPM to store it more securely, but it is up to you.

initial git setup and choice of provider is not enforced. The project does not automatically configure git for your newly created /etc/nixos.
Once a git repo is detected, snowglobe-rebuild will attempt to sync commits and track updates through an updates.log file if you choose to use it.

I will not provide the constantly changing module tree here. You can browse available modules and their descriptions using ```nixos-rebuild repl```
or a third party program like ```nix-inspect``` https://github.com/bluskript/nix-inspect

Eventually, I plan to make a TUI which lets you control and set common options more easily.
