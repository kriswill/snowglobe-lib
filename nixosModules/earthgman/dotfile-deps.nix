# dependencies for my dotfiles: https://git.earthgman.dev/earthgman/dotfiles
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.dotfile-deps;
in
{
  options.earthgman.dotfile-deps = {
    enable = lib.mkEnableOption "dependencies for EarthGman's dotfiles";
  };

  config = lib.mkIf cfg.enable {
    # setup pam to allow decrypting of gpg key on login and through swaylock if your gpg key has the same password as your user
    security.pam.services = {
      swaylock.gnupg.enable = true;
      login.gnupg = {
        enable = true;
        storeOnly = true;
      };
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = builtins.attrValues {
        inherit (pkgs)
          # ensure gtk portal is installed
          xdg-desktop-portal-gtk
          xdg-desktop-portal-termfilechooser
          ;
      };
    };

    environment.systemPackages = builtins.attrValues ({
      inherit (pkgs)
        libnotify
        grim
        slurp
        xdg-utils
        xdg-user-dirs
        xwininfo
        mpd
        star-pixel-icons
        adw-gtk3
        ;
    });

    fonts.packages =
      builtins.attrValues ({
        inherit (pkgs)
          omori-font
          _8-bit-operator-font
          ;
      })
      ++ (builtins.attrValues {
        inherit (pkgs.nerd-fonts)
          meslo-lg
          ;
      });

    qt = {
      enable = lib.setDefault true;
      platformTheme = "kde";
      style = lib.setDefault "kvantum";
    };

    programs = {
      # disable defaults
      fuzzel.enable = lib.mkDefault false;
      alacritty.enable = lib.mkDefault false;

      # required programs
      bat.enable = true;
      brightnessctl.enable = true;
      dconf.enable = true;
      eza.enable = true;
      fzf.enable = true;
      lynx.enable = true;
      rofi.enable = true;
      git.enable = true;
      gnome-clocks.enable = true;
      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
      password-store.enable = true;
      pwvucontrol.enable = true;
      swayidle = {
        enable = true;
        systemd.enable = true;
      };
      zsh.enable = true;

      # TODO figure out how to replace programs.neovim so I can use that for custom packages
      neovim.enable = lib.mkForce false;
      vim.enable = lib.mkForce false;
      neovim-customized.enable = true; # provides unconfigured pkgs.nvim by default

      # optional programs. Modify at your own risk.
      awww = {
        enable = lib.setDefault true;
        systemd.enable = lib.setDefault true;
      };
      evince.enable = lib.setDefault true;
      firefox.enable = lib.setDefault true;
      gnome-calculator.enable = lib.setDefault true;
      gthumb.enable = lib.setDefault true;
      kitty.enable = lib.setDefault true;
      nautilus.enable = lib.setDefault true;
      nwg-look.enable = lib.setDefault true;
      qutebrowser.enable = lib.setDefault true;
      rmpc.enable = lib.setDefault true;
      selectdefaultapplication.enable = lib.setDefault true;
      starship.enable = lib.setDefault true;
      # swaylock must be used for pam-gnupg to work
      # https://github.com/cruegge/pam-gnupg
      swaylock.enable = lib.setDefault true;
      tmux.enable = lib.setDefault true;
      vlc.enable = lib.setDefault true;
      waybar.enable = lib.setDefault true;
      yazi.enable = lib.setDefault true;
      yt-dlp.enable = lib.setDefault true;
    };
  };
}
