{
  inputs,
  outputs,
  lib,
  ...
}:
{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = lib.autoImport ./. { exceptions = [ "overlays.nix" ]; } ++ [
    # core module modifications from nixpkgs
    ../core

    (import ./overlays.nix { inherit outputs lib config; })
    # improved nix-daemon
    inputs.determinate.nixosModules.default
    # improved disk partition management
    inputs.disko.nixosModules.default
    # secrets storage and key management
    inputs.sops-nix.nixosModules.default
  ];

  options.earthgman = {
    enable = lib.mkEnableOption "EarthGman's nixos modules and configurations";
  };

  config = lib.mkIf config.earthgman.enable {
    # my custom patches and configs
    # -----------------------------

    earthgman =
      let
        hasDesktop = (!(config.system.desktop == null));
      in
      {
        # apply optional overlays
        overlays = {
          awww-git.enable = lib.setDefault true;
          nh-git.enable = lib.setDefault true;
          niri-git.enable = lib.setDefault true;
          prismlauncher-git.enable = lib.setDefault true;
          yazi-git.enable = lib.setDefault true;
          zsh-syntax-highlighting-fix.enable = lib.setDefault true;
        };

        dynamic-timezone.enable = lib.setDefault (
          config.networking.networkmanager.enable && config.time.timeZone == null
        );
        headless-debloater.enable = lib.setDefault (!hasDesktop);
        desktop.enable = lib.setDefault hasDesktop;
        program-configs.enable = lib.setDefault true;
        nix-cache.enable = lib.setDefault true;
        garbage-collector.enable = lib.setDefault true;
        grub-config.enable = lib.setDefault true;
      };

    # populate public keyring (not present in nixpkgs. only used to hold data)
    keyring = {
      ssh = {
        earthgman = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKNRHd6NLt4Yd9y5Enu54fJ/a2VCrRgbvfMuom3zn5zg";
      };
      substitutors = {
        "nix-store.earthgman.dev" = config.earthgman.nix-cache.publicKey;
        "yazi.cachix.org" = "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k=";
      };
    };

    # patches from other repositories
    # -------------------------------

    # improved nix-daemon
    determinate.enable = lib.setDefault true;

    # core nixos modules
    # ------------------

    # extra trusted caches
    nix.settings = {
      substituters = [
        "https://yazi.cachix.org"
      ];
      trusted-public-keys = [
        config.keyring.substitutors."yazi.cachix.org"
      ];
    };

    nix = {
      # prefer to use flakes as channels are basically deprecated at this point
      channel.enable = lib.setDefault false;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        # enable hard linking of identical contents within the nix store
        auto-optimise-store = lib.setDefault true;
      };
    };

    nixpkgs = {
      hostPlatform = config.system.arch;
      config.allowUnfree = lib.setDefault true;
    };

    # remove nixos documentation
    documentation.nixos.enable = lib.setDefault false;

    # enable the linux-firmware repository if we are not in a virtual machine
    # TODO only qemu is supported
    hardware.enableRedistributableFirmware = lib.setDefault (!config.system.isQemu);

    networking = {
      networkmanager.enable = lib.setDefault true;
      hostName = lib.setDefault config.system.name;
    };

    boot = {
      # everyone gets the latest kernel
      kernelPackages = lib.setDefault pkgs.linuxPackages_latest;
      # clean garbage from tmp
      tmp.cleanOnBoot = lib.setDefault true;

      loader = {
        # allow the installer to change boot order / other important variables for UEFI systems
        efi.canTouchEfiVariables = lib.setDefault true;
        # give the user more time to select configurations for slower monitors
        timeout = lib.setDefault 10;
      };
    };

    # programs.bash.enable uses lib.mkDefault or lib.mkOverride 900 for this option
    # note the package option is not provided by nixpkgs, the shell modules are kind of poorly written imo
    users.defaultUserShell = lib.mkOverride 899 config.programs.zsh.package;

    environment = {
      # use dash as /bin/sh of choice
      # once again, override weights are hardcoded into nixpkgs
      binsh = lib.mkOverride 899 "${pkgs.dash}/bin/dash";
    };

    # make sure that the virtual console respects the keymap chosen in the installer
    console.useXkbConfig = lib.setDefault true;

    # enable tools
    programs = {
      # custom wrapper scripts
      tmux-helper.enable = lib.setDefault true;
      nixos-rebuild-helper.enable = lib.setDefault true;

      # cat with colorized output
      bat.enable = lib.setDefault true;
      # brightness control
      brightnessctl.enable = lib.setDefault true;
      # improved bash shell with plugin support
      zsh.enable = lib.setDefault true;
      # wrapper around several nixos tools
      nh.enable = lib.setDefault true;
      # declarative disk partitioning tool
      disko.enable = lib.setDefault true;
      # bloat finder
      ncdu.enable = lib.setDefault true;
      # terminal multiplexer
      tmux.enable = lib.setDefault true;
      # editor
      neovim-customized.enable = lib.mkDefault true;
      # system information
      fastfetch.enable = lib.setDefault true;
      # command history finder
      hstr.enable = lib.setDefault true;
      # very good picker tool for CLI
      fzf.enable = lib.setDefault true;
      # make ls output prettier
      eza.enable = lib.setDefault true;
      # make your shell prompt prettier
      starship.enable = lib.setDefault true;
      # jump to visited directories
      zoxide.enable = lib.setDefault true;
      # better top
      btop.enable = lib.setDefault true;
      # fuzzy finder and manager for systemd units
      sysz.enable = lib.setDefault true;
      # open source version control system
      git.enable = lib.setDefault true;
      # TUI for managing git operations
      lazygit.enable = lib.setDefault config.programs.git.enable;
      # better grep
      ripgrep.enable = lib.setDefault true;
      # tui file manager
      yazi.enable = lib.mkDefault true;
    };

    services = {
      # run openssh by default
      openssh.enable = lib.setDefault true;
      # improved dbus
      dbus.implementation = lib.setDefault "broker";
    };
  };
}
