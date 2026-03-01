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
          disko-git.enable = lib.setDefault true;
          niri-git.enable = lib.setDefault true;
          prismlauncher-git.enable = lib.setDefault true;
          yazi-git.enable = lib.setDefault true;
          zsh-syntax-highlighting-fix.enable = lib.setDefault true;
        };

        # assert config for how the system will start
        boot-config.enable = lib.setDefault true;

        # enable gpu modules
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
        hardware-tools.enable = lib.setDefault true;
        headless-debloater.enable = lib.setDefault (!hasDesktop);
        desktop.enable = lib.setDefault hasDesktop;
        program-configs.enable = lib.setDefault true;
        garbage-collector.enable = lib.setDefault true;
        sops-config.enable = lib.setDefault true;
      };

    # populate public keyring (not present in nixpkgs. only used to hold data)
    keyring = {
      ssh = {
        earthgman = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKNRHd6NLt4Yd9y5Enu54fJ/a2VCrRgbvfMuom3zn5zg";
      };
      substitutors =
        let
          substituters = config.earthgman.substituters;
        in
        {
          "nix-store.earthgman.dev" = substituters."nix-store.earthgman.dev".publicKey;
          "yazi.cachix.org" = substituters."yazi.cachix.org".publicKey;
        };
      openpgp = {
        earthgman = ''
          -----BEGIN PGP PUBLIC KEY BLOCK-----

          mDMEaLTOMBYJKwYBBAHaRw8BAQdAC1fsH2BhYY9VCMqkJwPekT32bcroQ+gBMe9N
          Hm/+JSm0L0VhcnRoR21hbiAoTWFpbiBrZXkpIDxFYXJ0aEdtYW5AcHJvdG9ubWFp
          bC5jb20+iJAEExYKADgWIQSgbB5yRiZ7TO4WzC5IYjHNvOOqMgUCaRCjywIbAwUL
          CQgHAgYVCgkICwIEFgIDAQIeAQIXgAAKCRBIYjHNvOOqMjt+AP0WThFKGwZ02nB7
          cOCaSkpqg3Pbhj4HpxQi92/qNemW7QEA+L1NoxCv71aR3usv+dC2PZczvdjBkA9V
          iU6GVszSLwi4OARotM4wEgorBgEEAZdVAQUBAQdAWV1n8dxP9+ttfvFnzhtQBwUn
          HHlCHFRChKYTmlTeIksDAQgHiHgEGBYKACAWIQSgbB5yRiZ7TO4WzC5IYjHNvOOq
          MgUCaLTOMAIbDAAKCRBIYjHNvOOqMgbGAPsG0x9ClE3Shl4Rr/GZv8/+h0gmNYS/
          3ERCquDYW/4sKwD6A1H8ShG4KK+6nzkIcfAeokIeRdaykZ7Ba4FN8DiKwg4=
          =JTSG
          -----END PGP PUBLIC KEY BLOCK-----
        '';
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

    # enable the linux-firmware repository if not in a virtual machine
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
      };
    };

    # programs.bash.enable uses lib.mkDefault or lib.mkOverride 900 for this option
    # note the package option is not provided by nixpkgs, the shell modules are kind of poorly written imo
    users.defaultUserShell = lib.mkOverride 899 config.programs.zsh.package;

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

    # enable tools
    programs = {
      # custom wrapper scripts
      tmux-helper.enable = lib.setDefault true;
      nixos-rebuild-helper.enable = lib.setDefault true;

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
