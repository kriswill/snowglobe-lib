{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-lib.profiles.hardware-tools;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib.profiles.hardware-tools.enable =
    lib.mkEnableOption "hardware diagnostic tools";
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.cpufreq = slib.setDefault true;
        environment.systemPackages = builtins.attrValues {
          inherit (pkgs)
            usbutils
            hdparm
            nvme-cli
            lm_sensors
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
