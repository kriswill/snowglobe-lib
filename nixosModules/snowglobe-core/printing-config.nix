{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.earthgman.printing-config;
in
{
  options.earthgman.printing-config = {
    enable = lib.mkEnableOption "EarthGman's CUPS printing configuration";
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
