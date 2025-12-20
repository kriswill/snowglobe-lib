{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "cutentr";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "a streaming client for the new Nintendo 3DS running NTR custom firmware";
    programName = program-name;
    packageName = program-name;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    # port must be open for 3ds to properly connect
    networking.firewall.allowedUDPPorts = [ 8001 ];
  };
}
