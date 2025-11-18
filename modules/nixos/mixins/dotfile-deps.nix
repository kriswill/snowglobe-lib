# dependencies of my personal dotfiles
{
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
    programs = {
      cava.enable = true;
      cmatrix.enable = true;
      cbonsai.enable = true;
      sl.enable = true;
      pipes.enable = true;
      # terminal
      alacritty.enable = false;
      kitty.enable = lib.mkDefault true;
      lynx.enable = true;

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

    # tray applet for networkmanager
    services.nm-applet.enable = lib.mkDefault true;
  };
}
