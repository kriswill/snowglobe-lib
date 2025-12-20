{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "password-store";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "a cli based password manager";
    programName = program-name;
    packageName = "pass";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
