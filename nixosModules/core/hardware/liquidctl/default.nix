{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.hardware.liquidctl;
in
{
  options.hardware.liquidctl = lib.mkProgramOption {
    description = "a tool for configuring your liquid coolers";
    programName = "liquidctl";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    services.udev.packages = [
      cfg.package
    ];
  };
}
