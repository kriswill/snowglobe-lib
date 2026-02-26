{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.garbage-collector;
in
{
  options.earthgman.garbage-collector = {
    enable = lib.mkEnableOption "EarthGman's nix garbage collector configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep 2";
      };
    };
  };
}
