{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.programs.yash;
in
{
  options.programs.yash = {
    enable = lib.mkEnableOption "yash";
    package = lib.mkPackageOption pkgs "yash" { };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [ cfg.package ];
      shells = [
        "/run/current-system/sw/bin/yash"
        "${cfg.package}/bin/yash"
      ];
    };
  };
}
