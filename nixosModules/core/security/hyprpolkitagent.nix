{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.security.hyprpolkitagent;
in
{
  options.security.hyprpolkitagent = lib.mkProgramOption {
    description = "Hyprland's polkit agent.";
    programName = "hyprpolkitagent";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    systemd.user.services.hyprpolkitagent = {
      path = [ cfg.package ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "exec";
        ExecStart = "${cfg.package}/libexec/hyprpolkitagent";
        Restart = "on-failure";
        RestartSec = 5;
        Slice = "session.slice";
      };
      unitConfig = {
        After = "graphical-session.target";
        ConditionEnvironment = [
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP=Hyprland"
        ];
        Description = "hyprland polkit agent";
        PartOf = "graphical-session.target";
      };
    };
  };
}
