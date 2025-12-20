{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "mutt-wizard";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "a helper for neomutt developed by LukeSmithXyz";
    programName = program-name;
    packageName = program-name;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    # requred dependency of mw
    programs.password-store.enable = true;
    environment = {
      systemPackages = [
        cfg.package
      ];
      pathsToLink = [
        "/share/mutt-wizard"
      ];
    };
  };
}
