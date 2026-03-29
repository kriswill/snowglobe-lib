{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "kdenlive";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "nonlinear video editor";
    programName = programName;
    packageName = programName;
    pkgs = pkgs.kdePackages;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
    }
  );
}
