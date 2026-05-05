{
  pkgs,
  lib,
  modulesPath,
  ...
}:
let
  install-sh = pkgs.writeScriptBin "install.sh" (
    builtins.readFile ../../lib/scripts/snowglobe-install.sh
  );
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
    Welcome to the Snowglobe NixOS installer.

    It is recommended to set password for the root user with `sudo passwd` to log in over ssh

    Begin install by running `install.sh` as root.
  '';

  users.defaultUserShell = pkgs.zsh;
  environment = {
    systemPackages = [
      install-sh
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
      "disko/defaults/default-ext4-luks.nix".source = ../../lib/mixins/disko/default-ext4-luks.nix;
      "disko/defaults/default-ext4.nix".source = ../../lib/mixins/disko/default-ext4.nix;
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
    zsh.enable = true;
    # allow signing in to git for private repositories
    gh.enable = true;

    # declarative formatting of disks using nix files
    disko.enable = true;
  };
}
