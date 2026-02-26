{ config, ... }:
{
  users.users.root.openssh.authorizedKeys.keys = [
    config.keyring.ssh.earthgman
  ];
}
