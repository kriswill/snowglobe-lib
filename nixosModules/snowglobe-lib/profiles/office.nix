{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-lib.profiles.office;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib.profiles.office = {
    enable = lib.mkEnableOption "tools and programs typically found in an office setting";
  };

  config = lib.mkIf cfg.enable {
    # enable a working printing server by default
    services = {
      avahi = {
        enable = slib.setDefault true;
        nssmdns4 = slib.setDefault true;
        openFirewall = slib.setDefault true;
      };
      printing = {
        enable = slib.setDefault true;
        browsed.enable = slib.setDefault false;
        drivers = (
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

    programs = {
      # email
      thunderbird.enable = slib.setDefault true;
      # open source MSoffice
      libreoffice.enable = slib.setDefault true;
      # image editor
      gimp.enable = slib.setDefault true;
      # provide chromium as a backup browser in case something on firefox doesn't work due to poor web engineering
      chromium.enable = slib.setDefault true;
    };
  };
}
