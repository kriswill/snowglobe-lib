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
  imports = lib.importModules ./. { exceptions = [ "overlays.nix" ]; } ++ [
    # core module modifications from nixpkgs
    ../nixos

    # special case for overlays where outputs needs to be explicitly provided
    (import ./overlays.nix { inherit outputs lib config; })
    # improved nix-daemon
    inputs.determinate.nixosModules.default
    # improved disk partition management
    inputs.disko.nixosModules.default
    # secrets storage and key management
    inputs.sops-nix.nixosModules.default
  ];

  options.snowglobe-core = {
    enable = lib.mkEnableOption "Snowglobe-Core's nixos modules and configurations";
  };

  config = lib.mkIf config.snowglobe-core.enable {
    # custom patches and configs
    # -----------------------------
    snowglobe-core =
      let
        hasDesktop = (!(config.system.desktop == null));
      in
      {
        # config for how the system will start
        boot-config.enable = lib.setDefault true;

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

        # extra caches
        substituters = {
          "nix-store.earthgman.dev".enable = lib.setDefault true;
          "yazi.cachix.org".enable = lib.setDefault true;
        };

        # other stuff
        dynamic-timezone.enable = lib.setDefault (
          config.networking.networkmanager.enable && config.time.timeZone == null
        );
        headless-debloater.enable = lib.setDefault (!hasDesktop);
        desktop.enable = lib.setDefault hasDesktop;
        program-configs.enable = lib.setDefault true;
        garbage-collector.enable = lib.setDefault true;
        sops-config.enable = lib.setDefault true;
      };

    # populate public keyring (not present in nixpkgs. only used to hold data)
    keyring = {
      substitutors =
        let
          substituters = config.snowglobe-core.substituters;
        in
        {
          "nix-store.earthgman.dev" = substituters."nix-store.earthgman.dev".publicKey;
          "yazi.cachix.org" = substituters."yazi.cachix.org".publicKey;
        };
    };

    # patches from other repositories
    # -------------------------------

    # improved nix-daemon
    determinate.enable = lib.setDefault true;

    # core nixos modules
    # ------------------

    nix = {
      # prefer to use flakes as channels are basically deprecated at this point
      channel.enable = lib.setDefault false;
      settings = {
        # allow fallbacks if a substitutor is down
        fallback = lib.setDefault true;
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
      config = {
        allowUnfree = lib.setDefault true;
        permittedInsecurePackages = [
          # TODO remove me later
          # needed for stoat-desktop
          "electron-38.8.4"
        ];
      };
    };

    # remove nixos documentation
    documentation.nixos.enable = lib.setDefault false;

    # enable the linux-firmware repository if not in a virtual machine
    # TODO only qemu is supported
    hardware.enableRedistributableFirmware = lib.setDefault (!config.system.isVM);

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
      };
    };

    environment = {
      # use dash as /bin/sh of choice
      # once again, override weights are hardcoded into nixpkgs
      binsh = lib.mkOverride 899 "${pkgs.dash}/bin/dash";

      # these are not set properly on nixos by default for some reason
      sessionVariables = {
        SYSTEMD_KEYMAP_DIRECTORIES = lib.setDefault "${pkgs.kbd}/share/keymaps";
      };
    };

    # make sure that the virtual console respects the keymap chosen in the installer
    console.useXkbConfig = lib.setDefault true;

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
      bat.enable = lib.setDefault config.programs.tmux.enable;
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
      neovim = {
        enable = lib.setDefault true;
        viAlias = lib.setDefault true;
        vimAlias = lib.setDefault true;
      };
      # system information
      fastfetch.enable = lib.setDefault true;
      # file info fetcher
      file.enable = lib.setDefault true;
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
      # wrapper script for nixos-rebuild
      snowglobe-rebuild.enable = lib.setDefault true;
      # open source version control system
      git.enable = lib.setDefault true;
      # TUI for managing git operations
      lazygit.enable = lib.setDefault config.programs.git.enable;
      # better grep
      ripgrep.enable = lib.setDefault true;
      # tui file manager
      yazi.enable = lib.setDefault true;
      # cli archive maker
      zip.enable = lib.setDefault true;
    };

    services = {
      # run openssh by default
      openssh.enable = lib.setDefault true;
      # improved dbus
      dbus.implementation = lib.setDefault "broker";
    };
  };
}
