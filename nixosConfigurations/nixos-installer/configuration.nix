# EarthGman's custom installer ISO
{
  pkgs,
  lib,
  modulesPath,
  ...
}:
let
  install-sh = pkgs.writeScriptBin "install.sh" (builtins.readFile ./install.sh);
  nixfmt-sh = pkgs.writeScriptBin "nixfmt.sh" (builtins.readFile ../../scripts/nixfmt.sh);
in
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  hardware = {
    # To get drivers for various wireless devices
    enableRedistributableFirmware = lib.mkDefault true;

    # no need for these on an installer
    cpu.intel.updateMicrocode = false;
    cpu.amd.updateMicrocode = false;
  };

  services.getty.helpLine = lib.mkForce ''
    Welcome to EarthGman's NixOS installer.

    To log in over ssh, set a password for the root user with `sudo passwd`

    Begin install by running `install.sh` as root.
  '';

  environment = {
    systemPackages = [
      install-sh
      nixfmt-sh
    ]
    ++ (builtins.attrValues {
      inherit (pkgs)
        nixfmt
        sops
        age
        ;
    });

    etc = {
      # TODO technically etc is not the correct place to put this
      # provide a comprehensive list of locales for the locale selector
      "locales.txt".source = ../../lib/mixins/locales.txt;

      # provide disko configurations for the installer
      "disko/defaults/luks-legacy-ext4.nix".source = ../../lib/mixins/disko/luks-legacy-ext4.nix;
      "disko/defaults/luks-uefi-ext4.nix".source = ../../lib/mixins/disko/luks-uefi-ext4.nix;
      "disko/defaults/legacy-ext4.nix".source = ../../lib/mixins/disko/legacy-ext4.nix;
      "disko/defaults/uefi-ext4.nix".source = ../../lib/mixins/disko/uefi-ext4.nix;
    };
  };

  # zsh will complain about no config file in the home directory
  system = {
    userActivationScripts = {
      create-zshrc = ''
        if [ ! -e "$HOME/.zshrc" ]; then
          printf "#" >"$HOME/.zshrc"
        fi
      '';
    };
    # determinate nixd is not started for some reason?
    activationScripts = {
      start-nix-daemon = ''
        if ! systemctl is-active nix-daemon; then
          systemctl start nix-daemon
        fi
      '';
    };
  };

  boot = {
    # disables zfs, bcachefs
    #TODO figure out how to use zfs
    supportedFilesystems = lib.mkForce [
      "auto"
      #"bcachefs"
      "btrfs"
      "cifs"
      "ext4"
      "f2fs"
      "jfs"
      "ntfs"
      "overlay"
      "reiserfs"
      "squashfs"
      "tmpfs"
      "vfat"
      "xfs"
      # "zfs"
    ];
  };

  programs = {
    neovim-customized = {
      enable = true;
      defaultEditor = true;
      # custom build of neovim with only nix lsp
      installGlobally = true;
      package = pkgs.earthgman.neovim-nix;
    };

    # allow signing in to git for private repositories
    gh.enable = true;

    # declarative formatting of disks using nix files
    disko.enable = true;
  };
}
