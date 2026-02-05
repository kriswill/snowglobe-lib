# Modules enabled by `gman.enable` for NixOS
{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = lib.autoImport ./.;

  options.gman = {
    enable = lib.mkEnableOption "gman's nixos modules";

    ssh-keys = lib.mkOption {
      description = "gman's public ssh-keys";
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };

  config = lib.mkIf config.gman.enable {
    gman = {
      ssh-keys = {
        g = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKNRHd6NLt4Yd9y5Enu54fJ/a2VCrRgbvfMuom3zn5zg";
        cypher = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPk0JEmiuM5xR5JlCjU7EdNVZlztCeXOHkTXKVsOKeW8";
        think-one = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKIkw34vAW/O+Ev1kHG+aLpKxKANzUYGlm//EFELE+lA";
      };

      # default mixins
      # use grub by default as it supports legacy bios
      grub.enable = lib.mkDefault true;
      # improved nixos rebuild
      nh.enable = lib.mkDefault true;

      # patch for automatically setting the timezone based on your current geolocation through networkmanager
      geolocation-timezones.enable = lib.mkDefault (
        config.networking.networkmanager.enable && config.time.timeZone == null
      );

      # enable mixins based on host metadata
      # see /modules/nixos/mixins/desktop.nix
      desktop.enable = (config.meta.desktop != "");
      # see /modules/nixos/mixins/sops.nix
      sops.enable = true;

      server.enable = (config.meta.specialization == "server");

      gaming.enable = (config.meta.specialization == "gaming");

      # gpu modules and drivers
      gpu.intel.enable = (config.meta.gpu == "intel");
      gpu.nvidia.enable = (config.meta.gpu == "nvidia");
      gpu.amd.enable = (config.meta.gpu == "amd");
    };

    nix.settings = {
      substituters = [
        "https://nix-store.earthgman.dev/"
        "https://yazi.cachix.org"
      ];
      trusted-public-keys = [
        "nix-store.earthgman.dev:2Qrw9kS+K2c00ikcgaz5Y0M7j5XmkhFJz3d7oNgJdLw="
        "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      ];
      lazy-trees = true;
    };

    # Stock Nixos options
    # ------------------------------------------------------

    # its not the best anyway
    documentation.nixos.enable = lib.mkDefault false;

    boot = {
      # use latest nixpkgs linux kernel by default
      kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
      # remove all temporary socket and cache files on boot
      tmp.cleanOnBoot = lib.mkDefault true;
      kernelParams = [
        "quiet"
      ];
      loader = {
        efi.canTouchEfiVariables = lib.mkDefault true;
        # give the user more time to select configurations for slow monitors
        timeout = lib.mkDefault 10;
      };
    };

    # sync xserver and console keymaps
    console.useXkbConfig = lib.mkDefault true;

    networking = {
      hostName = lib.mkDefault config.meta.hostname;
      # hardware-configuration.nix has always had this on
      useDHCP = lib.mkDefault true;

      networkmanager.enable = lib.mkDefault true;
    };

    users = {
      # all users get zsh for login shell
      defaultUserShell = lib.mkOverride 800 pkgs.zsh;
    };

    nix = {
      # use flakes
      channel.enable = false;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        # enable hard linking of identical contents within the nix store
        auto-optimise-store = lib.mkDefault true;
      };
    };

    nixpkgs = {
      # set nixpkgs cpu architecture target
      hostPlatform = config.meta.system;

      config.allowUnfree = true;
    };

    # enable linux firmware if a physical machine
    hardware.enableRedistributableFirmware = lib.mkDefault (!config.meta.vm);

    environment = {
      # link /bin/sh to dash instead of a weird bash shell
      binsh = lib.mkOverride 899 "${pkgs.dash}/bin/dash";
      # small tools
      systemPackages = builtins.attrValues {
        inherit (pkgs)
          file
          zip
          # custom script for managing tmux sessions
          tmux-helper
          ;
      };
    };

    programs = {
      # modify default program option packages to better alternatives
      # better discord
      discord.package = lib.mkDefault pkgs.vesktop;
      # better firefox
      firefox.package = lib.mkDefault pkgs.librewolf;
      # password store otp plugin
      password-store.package = lib.mkDefault (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]));

      # nice tools
      disko.enable = lib.mkDefault true;
      ncdu.enable = lib.mkDefault true;
      fastfetch.enable = lib.mkDefault true;
      hstr.enable = lib.mkDefault true;
      fzf.enable = lib.mkDefault true;
      fd.enable = lib.mkDefault true;
      jq.enable = lib.mkDefault true;
      eza.enable = lib.mkDefault true;
      starship.enable = lib.mkDefault true;
      zoxide.enable = lib.mkDefault true;
      btop.enable = lib.mkDefault true;
      sysz.enable = lib.mkDefault true;
      # prefer custom modules for yazi, tmux, zsh and neovim.
      # configuring these using nix is literal hell and the default options mess with your ability to customize them from your home directory
      # instead, install a wrapped derivation that uses symlinkJoin to create a fully packaged and portable config.
      # additionally you can just set these to pkgs.tmux, pkgs.yazi or whatever and it will fully respect your imperative configs in /etc and your home directory.
      yazi-custom.enable = lib.mkDefault true;
      tmux-custom = {
        package = pkgs.gman.tmux;
        enable = lib.mkDefault true;
      };
      zsh-custom = {
        enable = lib.mkDefault true;
        package = lib.mkOverride 1337 pkgs.gman.zsh;
      };
      neovim-custom = {
        enable = lib.mkDefault true;
        viAlias = lib.mkDefault true;
        vimAlias = lib.mkDefault true;
      };
      git.enable = lib.mkDefault true;
      lazygit.enable = lib.mkDefault config.programs.git.enable;
      ripgrep.enable = lib.mkDefault true;
      bat.enable = lib.mkDefault true;
      # needed for basic nixos shell checks
      zsh.enable = lib.mkDefault true;
    };

    services = {
      # enable ssh by default
      openssh.enable = lib.mkDefault true;
      # controversial but necessary for uwsm
      dbus.implementation = lib.mkDefault "broker";
    };
  };
}
