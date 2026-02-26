{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "pwvucontrol";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "pipewire control frontend written in gtk";
    programName = programName;
    packageName = programName;
    extraOptions = {
      pavucontrolAlias = lib.mkEnableOption "pavucontrol alias";
    };
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules =
        let
          aliasPackage =
            if (cfg.pavucontrolAlias) then
              (pkgs.symlinkJoin {
                name = "pwvucontrol-alias";
                paths = [ cfg.package ];

                postBuild = ''
                  rm -f $out/bin/pwvucontrol-alias
                  ln -s $out/bin/pwvucontrol $out/bin/pavucontrol
                '';
              })
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
