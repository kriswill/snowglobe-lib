{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
  isUEFI = (config.snowglobe-lib.system.firmware == "UEFI");
in
{
  options.snowglobe-lib.boot-config.enable = lib.mkEnableOption "Snowglobe-Lib's grub configuration";

  config = lib.mkIf config.snowglobe-lib.boot-config.enable {
    boot = {
      # TODO look into this
      # plymouth.enable = lib.mkIf (config.system.desktop != null) slib.setDefault true;
      loader = {
        # give the user more time to select configurations for slower monitors
        timeout = slib.setDefault 10;
        grub = {
          enable = true;
          efiSupport = isUEFI;
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
          + lib.optionalString isUEFI ''
            menuentry 'UEFI Firmware Settings' --id 'uefi-firmware' {
              fwsetup
            }
          '';
        };
      };
    };
  };
}
