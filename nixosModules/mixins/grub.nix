{ lib, config, ... }:
{
  options.gman.grub.enable = lib.mkEnableOption "gman's grub configuration";

  config = lib.mkIf config.gman.grub.enable {
    boot.loader.grub = {
      enable = true;
      efiSupport = (config.meta.bios == "UEFI");
      devices = [ "nodev" ];
      gfxmodeEfi = lib.mkDefault "1920x1080";
      gfxmodeBios = lib.mkDefault "1920x1080";
      extraEntries = ''
        menuentry "Reboot" {
          reboot
        }
        menuentry "Poweroff" {
          halt
        } 
      ''
      + lib.optionalString (config.meta.bios == "UEFI") ''
        menuentry 'UEFI Firmware Settings' --id 'uefi-firmware' {
          fwsetup
        }
      '';
    };
  };
}
