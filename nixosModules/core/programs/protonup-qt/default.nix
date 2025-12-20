{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "protonup";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "a graphical frontend to manage proton versions";
    programName = program-name;
    packageName = "protonup-qt";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
