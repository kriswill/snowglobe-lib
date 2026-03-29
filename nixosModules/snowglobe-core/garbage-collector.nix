# wrapper around nh.clean
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
    numGenerations = lib.mkOption {
      description = "Number of generations to keep";
      type = lib.types.int;
      default = 2;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep ${toString cfg.numGenerations}";
      };
    };
  };
}
