{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "neomutt";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "TUI email client";
    programName = programName;
    packageName = programName;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        # install lukeSmithXYZ mutt helper
        programs.mutt-wizard.enable = lib.setDefault true;
      };
    }
  );
}
