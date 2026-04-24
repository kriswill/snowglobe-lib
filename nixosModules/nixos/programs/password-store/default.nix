{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "password-store";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    description = "a standard password manager for UNIX";
    programName = programName;
    packageName = "pass";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
      extraModules = {
        # enable the user to store git secrets in pass
        programs.pass-git-helper.enable = slib.setDefault config.programs.git.enable;
      };
    }
  );
}
