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
    extraOptions = {
      muttAlias = lib.mkOption {
        description = "whether to enable mutt -> neomutt alias";
        type = lib.types.bool;
        default = true;
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        # install lukeSmithXYZ mutt helper
        programs.mutt-wizard.enable = lib.setDefault true;
        environment.systemPackages =
          let
            mutt-alias = lib.mkProgramAlias {
              program = "neomutt";
              alias = "mutt";
              package = cfg.package;
              inherit pkgs;
            };
          in
          lib.mkIf cfg.muttAlias [
            mutt-alias
          ];
      };
    }
  );
}
