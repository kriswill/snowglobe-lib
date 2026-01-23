{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "mutt-wizard";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "a helper for neomutt developed by LukeSmithXyz";
    programName = program-name;
    packageName = program-name;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    # requred dependencies of mw
    programs = {
      password-store.enable = true;
      abook.enable = true;
      lynx.enable = true;
    };

    services.cron.enable = true;

    environment = {
      systemPackages = [
        cfg.package
      ]
      ++ (builtins.attrValues {
        inherit (pkgs)
          curl
          isync
          msmtp
          gettext
          notmuch
          urlscan
          mpop
          goimapnotify
          ;
      });
      # allow mutt-wizard config files to be accessible outside of /nix/store
      pathsToLink = [
        "/share/mutt-wizard"
      ];
    };
  };
}
