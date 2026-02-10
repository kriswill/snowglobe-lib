{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "tor-browser";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "Privacy-focused browser routing traffic through the Tor network";
    programName = program-name;
    packageName = program-name;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
