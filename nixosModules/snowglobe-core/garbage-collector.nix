# wrapper around nh.clean
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-core.garbage-collector;
in
{
  options.snowglobe-core.garbage-collector = {
    enable = lib.mkEnableOption "Snowglobe-Core's nix garbage collector configuration";
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
