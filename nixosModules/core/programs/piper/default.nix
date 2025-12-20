{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "piper";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "a mouse configuration utility and frontend for ratbagd";
    programName = program-name;
    packageName = program-name;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    # enable the corresponding service
    services.ratbagd.enable = true;
  };
}
