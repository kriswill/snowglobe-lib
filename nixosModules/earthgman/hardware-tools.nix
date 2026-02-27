{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.hardware-tools;
in
{
  options.earthgman.hardware-tools.enable = lib.mkEnableOption "hardware diagnostic tools";
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = builtins.attrValues {
          inherit (pkgs)
            usbutils
            hdparm
            pciutils
            lshw
            hwinfo
            inxi
            vdpauinfo
            libva-utils
            mesa-demos
            vulkan-tools
            clinfo
            ;
        };
      }
    ]
  );
}
