{
  pkgs,
  lib,
  config,
  ...
}:
{
  users.users.EarthGman = {
    openssh.authorizedKeys.keys = [
      config.keyring.ssh.earthgman
    ];
    isNormalUser = true;
    password = "123";
    extraGroups = [
      "wheel"
    ];
  };
}
