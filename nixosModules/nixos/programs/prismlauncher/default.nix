{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "prismlauncher";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "3rd party minecraft launcher";
    programName = programName;
    packageName = programName;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        # install runtime environment to system path
        # to prevent prismlauncher from asking every flake update
        environment.systemPackages = [ pkgs.jre ];
      };
    }
  );
}
