{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  cfg = config.services.polkit-gnome;
in
{
  options.services.polkit-gnome.enable = lib.mkEnableOption "desktop polkit agent from GNOME";

  config = lib.mkIf cfg.enable {
    systemd.user.services.polkit-gnome-authentication-agent-1 = slib.mkGraphicalService {
      serviceName = "polkit-gnome-1";
      package = pkgs.polkit_gnome;
      extraServiceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      };
    };
  };
}
