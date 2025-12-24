{
  pkgs,
  config,
  ...
}:
let
  username = "";
in
{
  sops.secrets."${username}_password".neededForUsers = true;
  users.users.${username} = {
    initialPassword = "";
    hashedPasswordFile = config.sops.secrets."${username}_password".path;
    password = null;
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
    ];
  };
}
