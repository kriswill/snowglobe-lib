{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "hping";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "Command-line oriented TCP/IP packet assembler/analyzer";
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
