{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "dolphin-emu";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "Wii and Gamecube emulator";
    programName = programName;
    packageName = programName;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        services.udev.packages = [ cfg.package ];
      };
    }
  );
}
