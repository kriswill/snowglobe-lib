{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "ryubing";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "nintendo switch emulator (community fork of ryujinx)";
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
