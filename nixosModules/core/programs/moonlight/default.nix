{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "moonlight";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "client for sunshine from lizardbyte";
    programName = program-name;
    packageName = "moonlight-qt";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
