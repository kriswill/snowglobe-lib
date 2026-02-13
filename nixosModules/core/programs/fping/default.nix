{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "fping";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "Send ICMP echo probes to network hosts";
    programName = program-name;
    packageName = program-name;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
