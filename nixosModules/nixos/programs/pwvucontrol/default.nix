{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "pwvucontrol";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    description = "pipewire control frontend written in gtk";
    programName = programName;
    packageName = programName;
    extraOptions = {
      pavucontrolAlias = lib.mkEnableOption "pavucontrol alias";
    };
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
      extraModules =
        let
          aliasPackage =
            if (cfg.pavucontrolAlias) then
              slib.mkProgramAlias {
                program = "pwvucontrol";
                alias = "pavucontrol";
                package = cfg.package;
                inherit pkgs;
              }
            else
              null;
        in
        lib.mkMerge [
          (lib.mkIf cfg.installGlobally {
            environment.systemPackages = lib.mkIf (aliasPackage != null) [
              aliasPackage
            ];
          })
          (lib.mkIf (cfg.installForUsers != [ ]) {
            users.users = lib.genAttrs cfg.installForUsers (username: {
              packages = lib.mkIf (aliasPackage != null) [ aliasPackage ];
            });
          })
        ];
    }
  );
}
