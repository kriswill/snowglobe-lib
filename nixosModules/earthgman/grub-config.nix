{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.earthgman.grub-config.enable = lib.mkEnableOption "EarthGman's grub configuration";

  config = lib.mkIf config.earthgman.grub-config.enable {
    boot.loader.grub = {
      enable = true;
      efiSupport = (config.system.firmware == "UEFI");
      devices = [ "nodev" ];
      gfxmodeEfi = lib.setDefault "1920x1080";
      gfxmodeBios = lib.setDefault "1920x1080";
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
}
