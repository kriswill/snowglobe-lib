{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "ryubing";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "nintendo switch emulator (community fork of ryujinx)";
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
