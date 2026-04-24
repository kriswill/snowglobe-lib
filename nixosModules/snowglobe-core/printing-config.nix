{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.snowglobe-core.printing-config;
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-core.printing-config = {
    enable = lib.mkEnableOption "Snowglobe-Core's CUPS printing configuration";
    installCommonDrivers = lib.mkOption {
      description = "Whether to install common printer drivers";
      type = lib.types.bool;
      default = true;
    };
  };
  config = lib.mkIf cfg.enable {
    services = {
      avahi = {
        enable = lib.mkDefault true;
        nssmdns4 = lib.mkDefault true;
        openFirewall = lib.mkDefault true;
      };
      printing = {
        enable = lib.mkDefault true;
        browsed.enable = lib.mkDefault false;
        drivers = lib.mkIf cfg.installCommonDrivers (
          builtins.attrValues {
            inherit (pkgs)
              # hp printers
              hplip
              # ghostscript
              gutenprint
              # samsung printers
              splix
              ;
          }
        );
      };
    };
  };
}
