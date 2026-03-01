{
  pkgs,
  lib,
  config,
  ...
}:
let
  module-name = "harden";
  cfg = config.earthgman.${module-name};
in
{
  options.earthgman.${module-name} = {
    enable = lib.mkEnableOption "EarthGman's hardening configuration for increased system security";
  };

  config = lib.mkIf cfg.enable {
    # boot.kernelPackages = pkgs.linuxPackages_hardened;
    # enable firewall and prevent the ping of death
    networking.firewall = {
      enable = true;
      allowPing = false;
    };

    # prevent users from being imperatively modified
    users.mutableUsers = false;

    # prevent password login over ssh
    services = {
      openssh.settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    # tool to determine how hard you are
    programs.kernel-hardening-checker.enable = lib.setDefault true;
  };
}
