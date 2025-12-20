{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "dolphin-emu";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "an emulator for the Nintendo gamecube and Wii";
    programName = program-name;
    packageName = program-name;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    # add the udev rules for wii remotes and GC controllers
    services.udev.packages = [
      cfg.package
    ];
  };
}
