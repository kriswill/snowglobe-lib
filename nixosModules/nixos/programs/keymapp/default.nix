{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "keymapp";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "monitoring and flashing software for zsa keyboards";
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
