{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.earthgman.boot-config.enable = lib.mkEnableOption "EarthGman's grub configuration";

  config = lib.mkIf config.earthgman.boot-config.enable {
    boot = {
      # TODO look into this
      # plymouth.enable = lib.mkIf (config.system.desktop != null) lib.setDefault true;
      loader = {
        # give the user more time to select configurations for slower monitors
        timeout = lib.setDefault 10;
        grub = {
          enable = true;
          efiSupport = (config.system.firmware == "UEFI");
          devices = [ "nodev" ];
          gfxmodeEfi = lib.setDefault "1920x1080";
          gfxmodeBios = lib.setDefault "1920x1080";
          # cool looking grub theme
          theme = lib.setDefault pkgs.nixos-grub-theme;
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
