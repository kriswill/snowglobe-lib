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
    };

    environment = {

      # force electron apps to run using wayland
      sessionVariables = {
        NIXOS_OZONE_WL = "1";
        # prevent blank screens with java applications running under xwayland-satellite
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };

      # add network manager applet schemas to XDG_DATA_DIRS
      # services.nm-applet.enable is not needed since it is provded by niri but the DATA DIRS path still needs to be set to render icons
      profiles = [ "${pkgs.networkmanagerapplet}" ];

      systemPackages = builtins.attrValues {
        inherit (pkgs)
          hyprpolkitagent # works on niri
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
        default = [
          "wlr"
          "gtk"
        ];
        # prevent nautilus from auto installing itself
        "org.freedesktop.impl.portal.FileChooser" = "gtk";
      };
    };
  };
}
