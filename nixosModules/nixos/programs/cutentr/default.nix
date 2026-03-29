{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "cutentr";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "3DS streaming client for linux";
    programName = programName;
    packageName = programName;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        networking.firewall.allowedUDPPorts = [ 8001 ];
      };
    }
  );
}
