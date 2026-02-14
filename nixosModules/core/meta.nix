{ lib, ... }:
{
  options.meta = {
    desktop = lib.mkOption {
      description = "which desktop environment is enabled";
      type = lib.types.str;
      default = "";
      example = "hyprland";
    };

    hostname = lib.mkOption {
      description = "system hostname";
      type = lib.types.str;
      default = "";
      example = "nixos";
    };

    secretsFile = lib.mkOption {
      description = "location of the default sops secrets file";
      type = lib.types.anything;
      default = null;
    };

    system = lib.mkOption {
      description = "cpu arch";
      type = lib.types.str;
      default = "x86_64-linux";
      example = "aarch64-linux";
    };

    bios = lib.mkOption {
      description = "x86 firmware implementation";
      type = lib.types.str;
      default = "UEFI";
      example = "legacy";
    };

    cpu = lib.mkOption {
      description = "x86 cpu brand";
      type = lib.types.str;
      default = "";
      example = "intel";
    };

    gpu = lib.mkOption {
      description = "x86 gpu brand";
      type = lib.types.str;
      default = "";
      example = "nvidia";
    };

    vm = lib.mkOption {
      description = "whether this host is a qemu virtual machine";
      type = lib.types.bool;
      default = false;
    };

    specialization = lib.mkOption {
      description = "The specialization modules for this host";
      type = lib.types.str;
      default = "";
    };

    ssh-keys = lib.mkOption {
      description = "library of public ssh keys";
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };
}
