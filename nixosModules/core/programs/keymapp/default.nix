{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "keymapp";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "an unfree app for configuring and flashing firmware for ZSA keyboards";
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
