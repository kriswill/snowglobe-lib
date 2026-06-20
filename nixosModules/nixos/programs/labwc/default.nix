{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.programs.labwc;
in
{
  options.programs.labwc.withUWSM = lib.mkEnableOption "UWSM for labwc";

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        systemd.packages = [ cfg.package ];
      }
      (lib.mkIf cfg.withUWSM {
        programs.uwsm = {
          enable = true;
          waylandCompositors.labwc = {
            prettyName = "LabWC";
            comment = "labwc managed by uwsm";
            binPath = "/run/current-system/sw/bin/labwc";
          };
        };
      })
    ]
  );
}
