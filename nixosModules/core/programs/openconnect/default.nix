{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "openconnect";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "open source alternative of cisco anyconnect";
    programName = programName;
    packageName = programName;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
    }
  );
}
