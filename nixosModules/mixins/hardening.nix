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
    enable = lib.mkEnableOption "gman's hardening module for NixOS";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      enable = true;
      allowPing = lib.mkDefault false;
    };
    services = {
      # prevent password login over ssh
      openssh.settings = {
        PasswordAuthentication = lib.mkDefault false;
        KbdInteractiveAuthentication = lib.mkDefault false;
      };
    };
  };
}
