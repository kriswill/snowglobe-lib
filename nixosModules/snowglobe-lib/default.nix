{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib = {
    enable = lib.mkEnableOption "Snowglobe-Lib's nixos modules and configurations";
  };

  config = lib.mkIf config.snowglobe-lib.enable {
    # custom patches and configs
    # -----------------------------
    snowglobe-lib =
      let
        hasDesktop = (!(config.system.desktop == null));
      in
      {
        # config for how the system will start
        boot-config.enable = slib.setDefault true;

        # enable gpu configurations
        gpu =
          let
            gpu-vendors = config.system.gpu-vendors;
          in
          {
            amd.enable = builtins.elem "amd" gpu-vendors;
            intel.enable = builtins.elem "intel" gpu-vendors;
            nvidia.enable = builtins.elem "nvidia" gpu-vendors;
          };

        # other stuff
        dynamic-timezone.enable = slib.setDefault (
          config.networking.networkmanager.enable && config.time.timeZone == null
        );
        headless-debloater.enable = slib.setDefault (!hasDesktop);
        desktop.enable = slib.setDefault hasDesktop;
        program-configs.enable = slib.setDefault true;
        garbage-collector.enable = slib.setDefault true;
        sops-config.enable = slib.setDefault true;
      };

    # core nixos modules
    # ------------------

    # extra caches
    # use of custom substitutor module;
    substituters = {
      "nix-store.earthgman.dev" = {
        # TODO figure out some way to allow users to disable this in the installer. I cannot be trusted >:)
        enable = slib.setDefault true;
        publicKey = "nix-store.earthgman.dev:2Qrw9kS+K2c00ikcgaz5Y0M7j5XmkhFJz3d7oNgJdLw=";
      };
      "yazi.cachix.org" = {
        enable = slib.setDefault true;
        publicKey = "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k=";
      };
    };

    nix = {
      # improved nix daemon
      package = slib.setDefault pkgs.lix;
      # prefer to use flakes as channels are basically deprecated at this point
      channel.enable = slib.setDefault false;
      settings = {
        # allow fallbacks if a substitutor is down
        fallback = slib.setDefault true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        # enable hard linking of identical contents within the nix store
        auto-optimise-store = slib.setDefault true;
      };
    };

    nixpkgs = {
      hostPlatform = config.system.arch;
      config = {
        allowUnfree = slib.setDefault true;
        permittedInsecurePackages = [
          # TODO remove me later
          # needed for stoat-desktop
          "electron-38.8.4"
        ];
      };
    };

    # remove nixos documentation
    documentation.nixos.enable = slib.setDefault false;

    # enable the linux-firmware repository if not in a virtual machine
    # TODO only qemu is supported
    hardware.enableRedistributableFirmware = slib.setDefault (!config.system.isVM);

    networking = {
      networkmanager.enable = slib.setDefault true;
      hostName = slib.setDefault config.system.name;
    };

    boot = {
      # everyone gets the latest kernel
      kernelPackages = slib.setDefault pkgs.linuxPackages_latest;
      # clean garbage from tmp
      tmp.cleanOnBoot = slib.setDefault true;

      loader = {
        # allow the installer to change boot order / other important variables for UEFI systems
        efi.canTouchEfiVariables = slib.setDefault true;
      };
    };

    environment = {
      # use dash as /bin/sh of choice
      # once again, override weights are hardcoded into nixpkgs
      binsh = lib.mkOverride 899 "${pkgs.dash}/bin/dash";

      # these are not set properly on nixos by default for some reason
      sessionVariables = {
        SYSTEMD_KEYMAP_DIRECTORIES = slib.setDefault "${pkgs.kbd}/share/keymaps";
      };
    };

    users.defaultUserShell = lib.mkOverride 899 config.programs.zsh.package;

    # make sure that the virtual console respects the keymap chosen in the installer
    console.useXkbConfig = slib.setDefault true;

    # make sure terminfo for popular terminals is installed
    environment.systemPackages = [
      pkgs.kitty.terminfo
      pkgs.alacritty.terminfo
      pkgs.foot.terminfo
      pkgs.ghostty.terminfo
      pkgs.wezterm.terminfo
      pkgs.st.terminfo
    ];

    # enable tools
    programs = {
      # alias to neovim
      vim.enable = lib.mkForce false;
      # cat with colorized output
      bat.enable = slib.setDefault config.programs.tmux.enable;
      # brightness control
      brightnessctl.enable = slib.setDefault true;
      # many useful unix utilities
      busybox.enable = slib.setDefault true;
      # wrapper around several nixos tools
      nh.enable = slib.setDefault true;
      # declarative disk partitioning tool
      disko.enable = slib.setDefault true;
      # bloat finder
      ncdu.enable = slib.setDefault true;
      # terminal multiplexer
      tmux.enable = slib.setDefault true;
      # editor
      neovim = {
        enable = slib.setDefault true;
        viAlias = slib.setDefault true;
        vimAlias = slib.setDefault true;
      };
      # system information
      fastfetch.enable = slib.setDefault true;
      # file info fetcher
      file.enable = slib.setDefault true;
      # very good picker tool for CLI
      fzf.enable = slib.setDefault true;
      # make ls output prettier
      eza.enable = slib.setDefault true;
      # json query tool
      jq.enable = slib.setDefault true;
      # better top
      btop.enable = slib.setDefault true;
      # fuzzy finder and manager for systemd units
      sysz.enable = slib.setDefault true;
      # wrapper script for nixos-rebuild
      snowglobe-rebuild.enable = slib.setDefault true;
      # open source version control system
      git.enable = slib.setDefault true;
      # TUI for managing git operations
      lazygit.enable = slib.setDefault config.programs.git.enable;
      # better grep
      ripgrep.enable = slib.setDefault true;
      # tui file manager
      yazi.enable = slib.setDefault true;
      # cli archive maker
      zip.enable = slib.setDefault true;
      # improved bash shell with plugin support
      zsh.enable = slib.setDefault true;
    };

    services = {
      # run openssh by default
      openssh.enable = slib.setDefault true;
      # improved dbus
      dbus.implementation = slib.setDefault "broker";
    };
  };
}
