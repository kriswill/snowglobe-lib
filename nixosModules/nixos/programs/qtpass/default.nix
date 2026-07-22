{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "qtpass";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    description = "graphical frontend to pass";
    programName = programName;
    packageName = programName;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
      extraModules = {
        programs = {
          password-store.enable = slib.setDefault true;
          git.enable = slib.setDefault true;
          pwgen.enable = slib.setDefault true;
          gnupg.agent.enable = true;
        };
      };
    }
  );
}
