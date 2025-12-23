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

        virtualisation = {
          spiceUSBRedirection.enable = true;
          libvirtd = {
            enable = true;
            qemu = {
              swtpm.enable = true;
              package = pkgs.qemu_kvm;
              # fix for: https://discourse.nixos.org/t/virt-manager-cannot-find-virtiofsd/26752/6
              vhostUserPackages = [ pkgs.virtiofsd ];
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
