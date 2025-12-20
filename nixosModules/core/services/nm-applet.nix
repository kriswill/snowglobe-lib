{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.nm-applet;
in
{
  options.services.nm-applet = {
    enable = lib.mkEnableOption "network manager applet daemon";

    package = lib.mkPackageOption pkgs "networkmanagerapplet" { };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [ cfg.package ];

      # set XDG_DATA_DIRS to include pkgs.networkmanagerapplet/share
      # required for gnome's environment assumptions
      # if this is not set then icons will not render on window managers
      profiles = [ "${cfg.package}" ];
    };

    systemd.user = {
      services.nm-applet = {
        path = [ cfg.package ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${cfg.package}/bin/nm-applet";
        };
        unitConfig = {
          After = "graphical-session.target";
          Description = "network manager applet";
          PartOf = "graphical-session.target";
        };
      };
    };
  };
}
