{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "nautilus";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "";
    programName = programName;
    packageName = programName;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        # mounting of network shares
        services.gvfs.enable = lib.setDefault true;
      };
    }
  );
}
