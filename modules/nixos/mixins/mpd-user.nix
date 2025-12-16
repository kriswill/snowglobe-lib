{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.mpd-user;
in
{
  options.gman.mpd-user = {
    enable = lib.mkEnableOption "gman's mpd per-user configuration";

    package = lib.mkPackageOption pkgs "mpd" { };
  };

  config = lib.mkIf cfg.enable {
    # disable nixos mpd configuration
    services.mpd.enable = lib.mkForce false;

    environment.systemPackages = [ cfg.package ];

    systemd.user = {
      services.mpd = {
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${cfg.package}/bin/mpd --systemd";
          Restart = "on-failure";
          RestartSec = 5;
        };
        unitConfig = {
          After = [
            "default.target"
            "sound.target"
          ];
          Description = "per-user mpd instance";
          PartOf = "default.target";
        };
      };
    };
  };
}
