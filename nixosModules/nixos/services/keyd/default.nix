# ensure the keyd cli is installed
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.keyd;
in
{
  environment.systemPackages = lib.mkIf cfg.enable [
    cfg.package
  ];
}
