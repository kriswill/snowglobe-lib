{
  pkgs,
  lib,
  config,
  ...
}:
let
  module-name = "libvirtd-qemu";
  cfg = config.snowglobe-core.${module-name};
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-core.${module-name} = {
    enable = lib.mkEnableOption "Snowglobe-Core's ${module-name} configuration";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = [ pkgs.dnsmasq ];
        boot.kernelModules =
          let
            cpu-vendor = config.system.cpu-vendor;
          in
          lib.mkIf (cpu-vendor != null) [ "kvm-${cpu-vendor}" ];
        networking.firewall.trustedInterfaces = [ "virbr0" ];

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
      (lib.mkIf (config.system.desktop != null) {
        programs.virt-manager.enable = slib.setDefault true;
      })
    ]
  );
}
