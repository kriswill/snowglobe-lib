{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "password-store";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "a standard password manager for UNIX";
    programName = programName;
    packageName = "pass";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        # enable the user to store git secrets in pass
        programs.pass-git-helper.enable = lib.setDefault config.programs.git.enable;
      };
    }
  );
}
