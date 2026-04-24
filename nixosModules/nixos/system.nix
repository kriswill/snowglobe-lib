# create some additional system options that can be populated by lib.mkNixosHost
{ lib, ... }:
{
  options.system = {
    arch = lib.mkOption {
      description = "architecture of your system";
      type = lib.types.str;
      default = "x86_64-linux";
      example = "aarch64-linux";
    };

    cpu-vendor = lib.mkOption {
      description = "Vendor of your cpu. (used for microcode updates and specific kernel modules)";
      type = lib.types.nullOr (
        lib.types.oneOf [
          lib.types.str
          "amd"
          lib.types.str
          "intel"
        ]
      );
      default = "";
    };

    gpu-vendors = lib.mkOption {
      description = "Vendor names of gpu devices present in your system (to enable drivers).";
      type = lib.types.listOf lib.types.str;
      example = [
        "nvidia"
        "intel"
        "amd"
      ];
      default = [ ];
    };

    desktop = lib.mkOption {
      description = "The desktop environment.";
      type = lib.types.nullOr (lib.types.str);
      default = null;
    };

    isVM = lib.mkOption {
      description = "Whether this host is a qemu virtual machine.";
      type = lib.types.bool;
      example = true;
      default = false;
    };

    firmware = lib.mkOption {
      description = "Firmware implmentation";
      type = lib.types.nullOr (
        lib.types.oneOf [
          lib.types.str
          "UEFI"
          lib.types.str
          "BIOS"
        ]
      );
      default = null;
    };
  };
}
