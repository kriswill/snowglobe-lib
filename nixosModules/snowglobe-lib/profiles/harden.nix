{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-lib.profiles.harden;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib.profiles.harden = {
    enable = lib.mkEnableOption "Snowglobe-Lib's hardening configuration for increased system security";
  };

  config = lib.mkIf cfg.enable {
    # TODO research hardened kernels
    # boot.kernelPackages = slib.overrideDefault pkgs.linuxPackages_hardened;

    # prevent users from being imperatively modified
    users.mutableUsers = slib.setDefault false;

    # prevent password login over ssh
    services = {
      openssh.settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };
}
