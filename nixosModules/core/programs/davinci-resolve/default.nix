{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "davinci-resolve";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "a proprietary non-linear video editor that runs on linux";
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
