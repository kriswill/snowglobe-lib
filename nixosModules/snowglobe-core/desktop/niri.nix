# ensures all the default stuff that niri expects is installed
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-core.desktop.niri;
in
{
  options.snowglobe-core.desktop.niri = {
    enable = lib.mkEnableOption "Snowglobe-Core's niri configuration.";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      niri = {
        enable = true;
      };

      # lock screen
      swaylock.enable = lib.setDefault true;

      # notification daemon
      swaync = {
        enable = lib.setDefault true;
        systemd.enable = lib.setDefault true;
      };

      # low battery notifier for laptops
      batsignal = {
        enable = lib.setDefault true;
        systemd.enable = lib.setDefault true;
      };

      # default terminal
      alacritty.enable = lib.setDefault true;

      # default picker
      fuzzel.enable = lib.setDefault true;

      # file manager
      nautilus.enable = lib.setDefault config.programs.niri.useNautilus;

      # blue light filter
      sunsetr.enable = lib.setDefault true;

      networkmanagerapplet.enable = true;

      waybar = {
        enable = lib.setDefault true;
        systemd.enable = lib.setDefault true;
      };

      # volume control
      pwvucontrol = lib.mkIf (config.services.pipewire.enable) {
        enable = lib.setDefault true;
        # some programs like waybar hardcode pavucontrol in their default config
        pavucontrolAlias = lib.setDefault true;
      };

      xwayland-satellite.enable = true;

      wl-clipboard.enable = lib.setDefault true;
    };

    # install a nerd font for icons
    fonts.packages = [ pkgs.nerd-fonts.meslo-lg ];

    # polkit agent written in gtk
    security.soteria.enable = lib.setDefault true;

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
        NIXOS_OZONE_WL = lib.setDefault "1";
        # fix blank screens with java applications running under xwayland-satellite
        _JAVA_AWT_WM_NONREPARENTING = lib.setDefault "1";
      };
      systemPackages = builtins.attrValues {
        inherit (pkgs)
          libnotify
          grim
          slurp
          ;
      };
    };
  };

}
