{
  lib,
  config,
  ...
}:
let
  cfg = config.gman.hardening;
in
{
  options.gman.hardening = {
    enable = lib.mkEnableOption "gman's linux hardening configuration";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.enable = true;
    services = {
      # prevent password login over ssh
      openssh.settings = {
        PasswordAuthentication = lib.mkDefault false;
        KbdInteractiveAuthentication = lib.mkDefault false;
      };
    };
  };
}
