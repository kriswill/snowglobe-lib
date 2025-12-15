# dependencies of my personal dotfiles
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.dotfile-deps;
in
{
  options.gman.dotfile-deps = {
    enable = lib.mkEnableOption "the services and programs that my personal dotfiles depend upon";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = builtins.attrValues (
      {
        inherit (pkgs)
          waybar
          libnotify
          wl-clipboard
          grim
          slurp
          swayidle
          coreutils-full
          findutils
          mpd
          xdg-utils
          xdg-user-dirs

          star-pixel-icons
          ;
      }
      // {
        # gets information regarding xwayland windows
        inherit (pkgs.xorg) xwininfo;
      }
    );

    gman.nix-development.enable = true;

    programs = {
      # optional programs
      cava.enable = lib.mkDefault true;
      cmatrix.enable = lib.mkDefault true;
      cbonsai.enable = lib.mkDefault true;
      sl.enable = lib.mkDefault true;
      firefox.enable = lib.mkDefault true;
      hstr.enable = lib.mkDefault true;
      pipes.enable = lib.mkDefault true;
      qutebrowser.enable = lib.mkDefault true;
      neovim-custom.enable = lib.mkDefault true;
      rmpc.enable = lib.mkDefault true;
      yt-dlp.enable = lib.mkDefault true;
      vlc.enable = lib.mkDefault true;
      gnome-calculator.enable = lib.mkDefault true;
      # gtk themer
      nwg-look.enable = lib.mkDefault true;
      # default pdf viewer
      evince.enable = lib.mkDefault true;
      # default image viewer
      gthumb.enable = lib.mkDefault true;
      # default graphical file manager
      dolphin.enable = lib.mkDefault true;

      # core dependencies
      swaylock.enable = true;
      selectdefaultapplication.enable = true;
      rofi.enable = true;
      password-store.enable = true;
      # use git auth with pass
      pass-git-helper.enable = true;
      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
      lynx.enable = true;
      dconf.enable = true;
      # terminals
      st.enable = true;
      # remove from default niri config
      alacritty.enable = false;
      kitty.enable = lib.mkDefault true;
      # setting timers
      gnome-clocks.enable = true;
      # pipewire control dashboard
      pwvucontrol.enable = true;

    };

    services = {
      # tray applet for networkmanager
      nm-applet.enable = lib.mkDefault true;

      # idle daemon
      swayidle = {
        enable = lib.mkDefault true;
        flags = [
          "-w"
          "-d"
        ];
      };

      # wayland wallpaper daemon
      awww = {
        enable = true;
        flags = lib.mkDefault [
          "-f"
          "argb"
        ];
      };
    };
  };
}
