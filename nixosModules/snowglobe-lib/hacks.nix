{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-lib.hacks;
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib.hacks = {
    polkit-gnome.enable = lib.mkEnableOption "the systemd unit for polkit gnome";
  };

  config = lib.mkIf config.snowglobe-lib.enable {
    # add labwc-session.target
    systemd.packages = lib.optionals config.programs.labwc.enable [ config.programs.labwc.package ];

    # ly does not allow services to start on login
    # https://codeberg.org/fairyglade/ly/issues/706
    systemd.services.display-manager.environment.XDG_CURRENT_DESKTOP =
      lib.mkIf (config.services.displayManager.ly.enable) "X-NIXOS-SYSTEMD-AWARE";

    # force polkit soteria to tear itself down properly on sessions not using uwsm like Niri
    systemd.user.services.polkit-soteria = lib.mkIf config.security.soteria.enable ({
      unitConfig = {
        Requisite = [ "graphical-session.target" ];
      };
    });

    systemd.user.services.polkit-gnome-autentication-agent-1 = lib.mkIf cfg.polkit-gnome.enable (
      slib.mkGraphicalService {
        serviceName = "polkit-gnome-1";
        package = pkgs.polkit_gnome;
        extraServiceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        };
      }
    );
  };
}
