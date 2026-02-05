{
  lib,
  config,
  ...
}:
{
  options.gman.server.enable = lib.mkEnableOption "gman's configuration for a server";

  config = lib.mkIf config.gman.server.enable (
    lib.mkMerge [
      (lib.mkIf (config.meta.bios == "UEFI") {
        gman.grub.enable = lib.mkForce false;
        boot.loader = {
          systemd-boot = {
            enable = lib.mkDefault true;
            configurationLimit = lib.mkDefault 2;
          };
        };
      })
      # use grub over systemd-boot for legacy bios implementations since systemd-boot is supported on UEFI only.
      (lib.mkIf (config.meta.bios == "legacy") {
        gman.grub.enable = true;
      })
      {
        gman = {
          debloat-nixos.enable = true;
          hardening.enable = true;
        };

        # remove emergency mode
        boot.initrd.systemd.suppressedUnits = lib.mkIf config.systemd.enableEmergencyMode [
          "emergency.service"
          "emergency.target"
        ];
        systemd = {
          enableEmergencyMode = false;
          sleep.extraConfig = ''
            AllowSuspend=no
            AllowHibernation=no
          '';
        };
      }
    ]
  );
}
