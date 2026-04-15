{ lib, config, ... }:
let
  cfg = config.programs.starship;
in
{
  environment.systemPackages = lib.mkIf cfg.enable [
    cfg.package
  ];
}
