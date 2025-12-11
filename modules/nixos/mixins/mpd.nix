{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.mpd;
in
{
  options.gman.mpd = {
    enable = lib.mkEnableOption "gman's custom mpd unit. Runs as your user instead of system";
    package = lib.mkPackageOption pkgs "mpd" { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
