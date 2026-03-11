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
        bibata-cursors
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
      sunsetr.enable = true;
      zsh = {
        enable = true;
        autosuggestions.enable = true;
        syntaxHighlighting.enable = true;
      };

      vim.enable = lib.mkForce false;
      neovim.enable = true;

      # optional programs. Modify at your own risk.
      # wallpaper daemon
      awww = {
        enable = lib.setDefault true;
        systemd.enable = lib.setDefault true;
      };
      # TUI email client
      neomutt.enable = true;
      # pdf viewer
      evince.enable = lib.setDefault true;
      # web browser
      firefox.enable = lib.setDefault true;
      gnome-calculator.enable = lib.setDefault true;
      # image viewer
      gthumb.enable = lib.setDefault true;
      kitty.enable = lib.setDefault true;
      # file manager
      nautilus.enable = lib.setDefault true;
      # gtk theme manager
      nwg-look.enable = lib.setDefault true;
      qutebrowser.enable = lib.setDefault true;
      rmpc.enable = lib.setDefault true;
      selectdefaultapplication.enable = lib.setDefault true;
      starship.enable = lib.setDefault true;
      # swaylock must be used for pam-gnupg to work
      # https://github.com/cruegge/pam-gnupg
      swaylock.enable = lib.setDefault true;
      tmux.enable = lib.setDefault true;
      # media player
      vlc.enable = lib.setDefault true;
      waybar.enable = lib.setDefault true;
      yazi.enable = lib.setDefault true;
      # required for rmpc to download youtube videos
      yt-dlp.enable = lib.setDefault true;
    };
  };
}
