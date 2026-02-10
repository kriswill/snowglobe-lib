{ pkgs, ... }:
{
  users.users.bob = {
    isNormalUser = true;
    description = "bob";
    shell = pkgs.zsh;
    password = "123";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
