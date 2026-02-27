# good defaults for servers
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.server-config;
in
{
  options.earthgman.server-config.enable = lib.mkEnableOption "EarthGman's server configuration.";

  config = lib.mkIf cfg.enable {
    earthgman = {
      # harden your server
      harden.enable = lib.setDefault true;
      # ensure garbage gets collected
      garbage-collector.enable = lib.setDefault true;
    };
  };
}
