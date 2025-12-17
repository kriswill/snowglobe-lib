{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.desktop.niri;
in
{
  options.gman.desktop.niri = {
    enable = lib.mkEnableOption "gman's niri configuration";
  };

  config = lib.mkIf cfg.enable {
    # install the needed stuff
    programs = {
      # niri module already enables gnome keyring daemon
      niri = {
        enable = true;
      };

      # default lockscreen
      swaylock.enable = true;

      # default terminal for niri
      alacritty.enable = lib.mkDefault true;
    };

    services = {
      # battery notifier / exits if no battery detected
      batsignal.enable = lib.mkDefault true;
      # setup a default notification daemon
      swaync.enable = lib.mkDefault true;
      nm-applet.enable = lib.mkDefault true;
    };

    # polkit agent that works on any desktop environment
    security.soteria.enable = lib.mkDefault true;

    environment = {
      # force electron apps to run using wayland
      sessionVariables = {
        NIXOS_OZONE_WL = "1";
        # prevent blank screens with java applications running under xwayland-satellite
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };

      systemPackages = builtins.attrValues {
        inherit (pkgs)
          libnotify # provides `notify-send`
          wl-clipboard
          grim # screenshots
          slurp # screen selector
          swayidle # daemonless swayidle
          xwayland-satellite # setup xwayland support for niri
          ;
      };
    };

    # global xdg portal configuration
    # uses wlr as primary with gtk as a fallback
    xdg.portal = {
      wlr.enable = true;
      config.niri = {
        default = lib.mkOverride 899 [
          "wlr"
          "gtk"
        ];
        # prevent nautilus from auto installing itself
        "org.freedesktop.impl.portal.FileChooser" = "gtk";
      };
    };
  };
}
