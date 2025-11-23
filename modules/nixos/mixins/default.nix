# Modules enabled by `gman.enable` for NixOS
# /modules/shared is also included
{
  pkgs,
  lib,
  config,
  ...
}:
# handle edge cases in display manager session names
{
  imports = lib.autoImport ./.;

  options.gman = {
    enable = lib.mkEnableOption "gman's nixos modules";

    ssh-keys = lib.mkOption {
      description = "public ssh keys for ease of access";
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };

  config = lib.mkIf config.gman.enable {
    gman = {
      ssh-keys = {
        g = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKNRHd6NLt4Yd9y5Enu54fJ/a2VCrRgbvfMuom3zn5zg";
        cypher = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPk0JEmiuM5xR5JlCjU7EdNVZlztCeXOHkTXKVsOKeW8";
      };

      # default mixins
      # use grub by default as it supports legacy bios
      grub.enable = lib.mkDefault true;
      # improved nixos rebuild
      nh.enable = lib.mkDefault true;
      # riced zsh
      zsh.enable = lib.mkDefault true;
      # tmux configuration
      tmux.enable = lib.mkDefault true;

      # enable mixins based on host metadata
      # see /modules/nixos/mixins/desktop.nix
      desktop.enable = (config.meta.desktop != "");
      # see /modules/nixos/mixins/sops.nix
      sops.enable = (config.meta.secretsFile != null);

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
      ];
      trusted-public-keys = [
        "nix-store.earthgman.dev:2Qrw9kS+K2c00ikcgaz5Y0M7j5XmkhFJz3d7oNgJdLw="
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
      tmp.cleanOnBoot = lib.mkDefault true;
      kernelParams = [
        "quiet"
      ];
      loader = {
        efi.canTouchEfiVariables = lib.mkDefault true;
        timeout = lib.mkDefault 10;
      };
    };

    # ensure that kanata keymaps transfer to virtual console TTY
    console.useXkbConfig = true;

    networking = {
      hostName = config.meta.hostname;
      # hardware-configuration.nix has always had this on
      useDHCP = lib.mkDefault true;

      # use networkmanager as im too lazy to learn wpa_supplicant
      wireless.enable = false; # disable wpa_supplicant
      networkmanager.enable = lib.mkDefault true;
    };

    users = {
      # users controlled by nix be default
      mutableUsers = lib.mkDefault false;

      # all users get zsh for login shell
      defaultUserShell = lib.mkOverride 800 pkgs.zsh;
    };

    nix = {
      # use flakes
      channel.enable = lib.mkDefault false;
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

    # enable microcode updates for bare metal machines
    # usually defined by hardware-configuration.nix but just in case its somehow not present
    hardware.cpu.${config.meta.cpu}.updateMicrocode = lib.mkIf (
      (!config.meta.vm) && (builtins.substring 0 3 config.meta.system) == "x86"
    ) (lib.mkDefault config.hardware.enableRedistributableFirmware);

    # install tools
    environment.systemPackages = [
      # keylogger
      pkgs.libinput

      pkgs.file

      # archive helpers
      pkgs.atool
      pkgs.unrar
    ]
    ++ lib.optionals (!config.meta.vm) [
      pkgs.brightnessctl
    ];

    programs = {
      # program for viewing your nix configuration
      nix-inspect.enable = lib.mkDefault true;

      # better version of discord
      discord.package = lib.mkDefault pkgs.vesktop;
      # password store otp plugin
      password-store.package = (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]));

      # system configuration viewer
      fastfetch.enable = lib.mkDefault true;

      # enable gpg key caching

      # more shell stuff
      zoxide = {
        enable = lib.mkDefault true;
        flags = lib.mkDefault [
          "--cmd j"
        ];
      };

      # nice tools
      ncdu.enable = lib.mkDefault true;
      hstr.enable = lib.mkDefault true;
      fzf.enable = lib.mkDefault true;
      fd.enable = lib.mkDefault true;
      eza.enable = lib.mkDefault true;
      btop.enable = lib.mkDefault true;
      sysz.enable = lib.mkDefault true;
      yazi.enable = lib.mkDefault true;
      git.enable = lib.mkDefault true;
      lazygit.enable = lib.mkDefault true;
      ripgrep.enable = lib.mkDefault true;
      zsh.enable = lib.mkDefault true;
      bat.enable = lib.mkDefault true;
      starship.enable = lib.mkDefault true;
      tmux.enable = lib.mkDefault true;
    };

    services = {
      # enable ssh by default
      openssh.enable = lib.mkDefault true;
      # controversial but necessary for uwsm
      dbus.implementation = lib.mkDefault "broker";
    };
  };
}
