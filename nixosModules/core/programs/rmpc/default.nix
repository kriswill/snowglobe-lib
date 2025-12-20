{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "rmpc";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "rusty frontend to mpd";
    programName = program-name;
    packageName = program-name;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      # provide mpd to path for user configuration
      # TODO test if services.mpd works
      pkgs.mpd
    ];
  };
}
