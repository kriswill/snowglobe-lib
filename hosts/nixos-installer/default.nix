# Gman's custom installer ISO
{
  pkgs,
  lib,
  config,
  modulesPath,
  ...
}:
let
  install-sh = pkgs.writeScriptBin "install.sh" (builtins.readFile ./install.sh);
  nixfmt-sh = pkgs.writeScriptBin "nixfmt.sh" (builtins.readFile ../../lib/mixins/nixfmt.sh);
in
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  gman = {
    hardware-tools.enable = true;
    # remove nix helper as it goes unused during the install process
    nh.enable = false;
    debloat-nixos.enable = lib.mkDefault true;
  };

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

    # these are not set properly on nixos by default for some reason
    sessionVariables = {
      SYSTEMD_KEYMAP_DIRECTORIES = "${pkgs.kbd}/share/keymaps";
    };

    etc = {
      # provide a comprehensive list of locales for the locale selector
      "locales.txt".source = ../../lib/mixins/locales.txt;

      # provide disko configurations for the installer
      "disko/defaults/luks-legacy.nix".source = ../../lib/mixins/disko/luks-legacy.nix;
      "disko/defaults/luks-uefi.nix".source = ../../lib/mixins/disko/luks-uefi.nix;
      "disko/defaults/default-legacy.nix".source = ../../lib/mixins/disko/default-legacy.nix;
      "disko/defaults/default-uefi.nix".source = ../../lib/mixins/disko/default-uefi.nix;
    };
  };

  # zsh will complain about no config file in the home directory
  system.userActivationScripts = {
    create-zshrc = ''
      if [ ! -e "$HOME/.zshrc" ]; then
        printf "#" >"$HOME/.zshrc"
      fi
    '';
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
    neovim-custom = {
      enable = true;
      defaultEditor = true;
      vimAlias = lib.mkDefault false;
      viAlias = lib.mkDefault false;
      # custom build of neovim with only nix lsp
      package = pkgs.gman.nvim-nix;
    };

    # allow signing in to github for private repositories
    gh.enable = true;

    # declarative formatting of disks using nix files
    disko.enable = true;
  };
}
