{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "kdenlive";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "nonlinear video editor from kde plasma";
    programName = program-name;
    packageName = program-name;
    pkgs = pkgs.kdePackages;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
