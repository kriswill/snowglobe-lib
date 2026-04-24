{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "mutt-wizard";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    inherit pkgs;
    description = "mutt helper from LukeSmithXYZ";
    programName = programName;
    packageName = programName;
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
      extraModules = {
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
  );
}
