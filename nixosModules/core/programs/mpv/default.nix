{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "mpv";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "lightweight media player";
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
