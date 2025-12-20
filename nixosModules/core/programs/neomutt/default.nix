# for all components of this module to work, you must enable pam-gnupg.so for "login"
# see https://github.com/cruegge/pam-gnupg for instructions
# for nixos use
# security.pam.services.login.pam-gnupg = {
#   enable = true;
#   storeOnly = true;
# }
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.programs.neomutt;
in
{
  options.programs.neomutt = lib.mkProgramOption {
    programName = "neomutt";
    description = "a tui email client";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    programs = {
      # address book
      abook.enable = lib.mkDefault true;
      # helper
      mutt-wizard.enable = lib.mkDefault true;
    };

    environment.systemPackages = [
      cfg.package
    ]
    ++ builtins.attrValues {
      inherit (pkgs)
        msmtp
        isync
        ;
    };
  };
}
