{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "fastfetch";
  cfg = config.programs.fastfetch;
in
{
  options.programs.fastfetch = lib.mkProgramOption {
    programName = program-name;
    description = "a fast fetcher for system info";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
