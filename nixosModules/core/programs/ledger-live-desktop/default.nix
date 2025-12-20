{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "ledger-live-desktop";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "frontend for bitcoin ledger wallets";
    programName = program-name;
    packageName = program-name;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    hardware.ledger.enable = true;
  };
}
