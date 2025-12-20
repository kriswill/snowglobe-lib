{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "kdiskmark";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "an open source disk diagnostic tool and alternative to crystal diskmark for windows";
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
