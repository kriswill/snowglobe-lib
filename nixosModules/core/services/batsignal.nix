{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.batsignal;
in
{
  options.services.batsignal = {
    enable = lib.mkEnableOption "battery monitor and alert daemon";
    flags = lib.mkOption {
      description = "extra flags passed to batsignal";
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    extraConfig = lib.mkOption {
      description = "configuration written to /etc/batsignal";
      type = lib.types.str;
      default = "";
    };

    package = lib.mkPackageOption pkgs "batsignal" { };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      etc."batsignal" = lib.mkIf (cfg.extraConfig != "") (pkgs.writeText cfg.extraConfig);
      systemPackages = [
        cfg.package
        pkgs.libnotify
      ];
    };

    systemd.user = {
      services.batsignal = {
        path = [ cfg.package ];
        wantedBy = [ "graphical-session-pre.target" ];
        serviceConfig = {
          Type = "exec";
          ExecStart =
            "${cfg.package}/bin/batsignal "
            + lib.optionalString (cfg.flags != [ ]) (lib.concatStringsSep " " cfg.flags);
          # let the service fail if no battery is found
          Restart = "no";
          Slice = "session.slice";
        };
        unitConfig = {
          After = "graphical-session-pre.target";
          Description = "batsignal";
          PartOf = "graphical-session-pre.target";
        };
      };
    };
  };
}
