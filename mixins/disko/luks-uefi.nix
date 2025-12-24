# password based luks encryption for uefi bios
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
                name = "nixos";
                settings.allowDiscards = true;
                # text file containing the password (only needed for formatting)
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
