# Yet another fleet manager for NixOS

**Similar projects & Inspirations**
- snowfall-lib - https://github.com/snowfallorg/lib
- clan-core - https://github.com/clan-lol/clan-core

**So, What is this?**

Short Answer:
A NixOS distribution / Opinionated NixOS Configuration builder based on flakes + some extra packages and nix functions you can import.

Long Answer:
automatic setup tools, NixOS module tweaks, fleet management automation, and preconfigured nix-community projects like disko and sops-nix
to assist with filling some of the holes and difficulties with managing your NixOS configurations.
It aims to be non-invasive, allowing you to freely change the provided flake structure or default settings provided by the modules.

**Some noteworthy features**
- dash as /bin/sh.
- lix instead of cppnix.
- disko instead fileSystems.
- sops-nix with age for secret management.
- public keyring database managed by the installer script (and you).
- optional rebuild wrapper for git synchronization across hosts and configuration state logging (snowglobe-rebuild).
- certain specialization profiles that enable configuration for specific purposes (gaming, office work, etc).
- many many extra program options for easier application management across your fleet (featuring per-user package scopes).
- package overlays for packages that are not fully functional or dont build at all from nixpkgs-unstable.
- automated installer environment which sets it all up.

# Getting Started

You can consume the modules directly using a nix flake

```flake.nix
{
  inputs = {
    snowglobe-lib.url = "https://codeberg.org/earthgman/snowglobe-lib";
    nixpkgs.follows = "snowglobe-lib/nixpkgs" # recommended but not required
  };

  outputs = { snowglobe-lib, nixpkgs }: 
  let
    slib = snowglobe-lib.lib;
  in
  {
    nixosConfigurations.myhostname = slib.mkNixosHost {
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

OR you can use the installer to install from scratch.

Pre-built images can be found at https://www.earthgman.dev/snowglobe-installers
These contain the scripts responsible for the automatic hardware detection, flake creation, and installation of the distribution.

You can also build these yourself if you have nix installed by using: nixos-rebuild build-image

Images marked as 'small' do not contain extra firmware from linux-firmware. They are useful for VMs or machines that dont need any blobs from it.
Images marked as 'untrusted' will ensure that the provided cache "nix-store.earthgman.dev" is disabled at all times.

Once booted the rest should be self-explanitory.


# Post install tips

You may wish to change the ownership of /etc/nixos to your underprivledged user so you can edit the config files.
If you do you will need to COPY (not move) /root/.config/sops/age/keys.txt to ~/.config/sops/age/keys.txt to access and modify your secrets.

initial git setup and choice of provider is up to you. The project does not automatically configure git for your newly created /etc/nixos.
once a git repo is detected, snowglobe-rebuild will attempt to sync commits and track updates through an updates.log file if you choose to use it.

I will not provide the constantly changing module tree here. You can browse available modules and their descriptions using ```nixos-rebuild repl```
or a third party program like ```nix-inspect``` https://github.com/bluskript/nix-inspect
