# ensures all the default stuff that niri expects is installed
{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
  cfg = config.snowglobe-lib.desktop.niri;
in
{
  options.snowglobe-lib.desktop.niri = {
    enable = lib.mkEnableOption "Snowglobe-Lib's niri configuration.";
  };

  config = lib.mkIf cfg.enable {
    # shared desktop configuration
    snowglobe-lib.desktop.enable = true;
    programs = {
      niri = {
        enable = true;
      };

      # lock screen
      swaylock.enable = slib.setDefault true;

      # notification daemon
      swaync = {
        enable = slib.setDefault true;
        systemd.enable = slib.setDefault true;
      };

      # low battery notifier for laptops
      batsignal = {
        enable = slib.setDefault true;
        systemd.enable = slib.setDefault true;
      };

      # default terminal
      alacritty.enable = slib.setDefault true;

      # default picker
      fuzzel.enable = slib.setDefault true;

      # file manager
      nautilus.enable = slib.setDefault config.programs.niri.useNautilus;

      # blue light filter
      sunsetr.enable = slib.setDefault true;

      # TODO a nixos module exists for this. Look into it
      networkmanagerapplet.enable = true;

      waybar = {
        enable = slib.setDefault true;
        # prevent 2 waybars from showing up due to niri's default config
        systemd.enable = slib.setDefault false;
      };

      # gtk volume control application for pipewire
      pwvucontrol = lib.mkIf (config.services.pipewire.enable) {
        enable = slib.setDefault true;
        # waybar hardcodes 'pavucontrol' in its default config
        pavucontrolAlias = slib.setDefault true;
      };

      # default xwayland implementation for niri
      xwayland-satellite.enable = slib.setDefault true;

      # clipboard tool for wayland
      wl-clipboard.enable = slib.setDefault true;
    };

    # install a nerd font for waybar icons
    fonts.packages = [ pkgs.nerd-fonts.meslo-lg ];

    # polkit agent written in gtk
    security.soteria.enable = slib.setDefault true;

    # service patches so they dont fail when exiting niri
    systemd.user.services = {
      # has caused alot of issues when exiting niri unless this is set
      polkit-soteria.unitConfig = {
        Requisite = [ "graphical-session.target" ];
      };
    };

    environment = {
      sessionVariables = {
        # force electron apps to run using wayland
        NIXOS_OZONE_WL = slib.setDefault "1";
        # fix blank screens with java applications running under xwayland-satellite
        _JAVA_AWT_WM_NONREPARENTING = slib.setDefault "1";
      };
      systemPackages = builtins.attrValues {
        inherit (pkgs)
          # notification daemon api
          libnotify
          ;
      };
    };
  };

}
