# password based luks encryption for legacy bios
{
  disko.devices = {
    disk = {
      nixos = {
        type = "disk";
        # CHANGE BEFORE FORMATTING
        # device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              type = "EF02";
              size = "1M";
            };
            esp = {
              name = "ESP";
              size = "256M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "root";
                settings.allowDiscards = true;
                # text file containing the password (only needed when formatting)
                passwordFile = "/tmp/secret.key";
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
  };
}
