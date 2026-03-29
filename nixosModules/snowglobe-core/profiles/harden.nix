{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-core.profiles.harden;
in
{
  options.snowglobe-core.profiles.harden = {
    enable = lib.mkEnableOption "Snowglobe-Core's hardening configuration for increased system security";
  };

  config = lib.mkIf cfg.enable {
    # boot.kernelPackages = pkgs.linuxPackages_hardened;
    # enable firewall and prevent the ping of death
    networking.firewall = {
      enable = true;
      allowPing = lib.setDefault false;
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
