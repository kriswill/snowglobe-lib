{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.libvirtd;
in
{
  # If you dont want libvirtd to requre sudo, add your user to the "libvirtd" group
  options.gman.libvirtd.enable = lib.mkEnableOption "gman's libvirtd configuration";
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        boot.kernelModules = lib.mkIf (config.meta.cpu != "") [ "kvm-${config.meta.cpu}" ];

        environment = {
          systemPackages = builtins.attrValues {
            inherit (pkgs)
              virtiofsd # file system sharing with VMs
              ;
          };
        };

        virtualisation = {
          spiceUSBRedirection.enable = true;
          libvirtd = {
            enable = true;
            qemu = {
              swtpm.enable = true;
              package = pkgs.qemu_kvm;
            };
          };
        };
      }
      (lib.mkIf (config.meta.desktop != "") {
        programs.virt-manager.enable = true;
      })
    ]
  );
}
