# unencrypted disko with just a boot and root partition
{
  disko.devices = {
    disk = {
      # disk label
      nixos = {
        # CHANGE PATH BEFORE FORMATTING (only applies to formatting)
        # device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              type = "EF00";
              size = "256M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
