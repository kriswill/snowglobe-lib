# profile for servers
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.server;
in
{
  imports = lib.autoImport ./. { };
  options.earthgman.server.enable = lib.mkEnableOption "EarthGman's server configuration.";

  config = lib.mkIf cfg.enable {
    earthgman = {
      # harden your server
      harden.enable = lib.setDefault true;
    };
  };
}
