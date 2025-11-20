{
  lib,
  config,
  ...
}:
{
  imports = lib.autoImport ./.;

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
      (lib.mkIf (config.meta.bios == "legacy") {
        gman.grub.enable = true;
      })
      {
        gman = {
          debloat.enable = true;
          security-hardening.enable = true;
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
