{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-core.boot-config.enable = lib.mkEnableOption "Snowglobe-Core's grub configuration";

  config = lib.mkIf config.snowglobe-core.boot-config.enable {
    boot = {
      # TODO look into this
      # plymouth.enable = lib.mkIf (config.system.desktop != null) slib.setDefault true;
      loader = {
        # give the user more time to select configurations for slower monitors
        timeout = slib.setDefault 10;
        grub = {
          enable = true;
          efiSupport = (config.system.firmware == "UEFI");
          devices = [ "nodev" ];
          gfxmodeEfi = slib.setDefault "1920x1080";
          gfxmodeBios = slib.setDefault "1920x1080";
          # cool looking grub theme
          theme = slib.setDefault pkgs.nixos-grub-theme;
          extraEntries = ''
            menuentry "Reboot" {
              reboot
            }
            menuentry "Poweroff" {
              halt
            } 
          ''
          + lib.optionalString (config.system.firmware == "UEFI") ''
            menuentry 'UEFI Firmware Settings' --id 'uefi-firmware' {
              fwsetup
            }
          '';
        };
      };
    };
  };
}
