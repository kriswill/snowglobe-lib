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
    environment.systemPackages = builtins.attrValues {
      inherit (pkgs)
        waybar
        libnotify
        wl-clipboard
        grim
        grimblast
        slurp
        swayidle
        ;
    };

    programs = {
      cava.enable = true;
      cmatrix.enable = true;
      cbonsai.enable = true;
      sl.enable = true;
      pipes.enable = true;

      # core dependencies
      swaylock.enable = true;
      rofi.enable = true;
      password-store.enable = true;
      gnupg.agent.enable = true;
      lynx.enable = true;

      # terminals
      st.enable = lib.mkDefault true;
      alacritty.enable = false;
      kitty.enable = lib.mkDefault true;

      # pipewire control dashboard
      pwvucontrol.enable = lib.mkDefault true;
      # pdf viewer
      evince.enable = lib.mkDefault true;
      # image viewer
      gthumb.enable = lib.mkDefault true;
      # graphical file manager
      dolphin.enable = lib.mkDefault true;
      # setting timers
      gnome-clocks.enable = lib.mkDefault true;

      # calculator
      gnome-calculator.enable = lib.mkDefault true;
      # gtk themer
      nwg-look.enable = lib.mkDefault true;
    };

    services = {
      # tray applet for networkmanager
      nm-applet.enable = lib.mkDefault true;

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
