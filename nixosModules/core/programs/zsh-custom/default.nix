{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "zsh-custom";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "custom wrapper for zsh";
    programName = program-name;
    packageName = "zsh";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
