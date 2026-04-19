{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "oksh";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    inherit pkgs;
    description = "OpenBSD Korn Shell";
    programName = programName;
    packageName = programName;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        environment.shells = lib.mkIf (cfg.installGlobally) [
          "/run/current-system/sw/bin/oksh"
        ];
      };
    }
  );
}
