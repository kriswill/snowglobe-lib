# # TODO
{
  #   pkgs,
  #   lib,
  #   config,
  #   ...
  # }:
  # let
  #   programName = "waybar";
  #   cfg = config.programs.${programName};
  # in
  # {
  #   options.programs.${programName} = lib.mkProgramOption {
  #     inherit pkgs;
  #     description = "Highly configurable status bar for wayland written in GTK";
  #     programName = programName;
  #     packageName = programName;
  #     excludedOptions = [
  #       "enable"
  #       "package"
  #     ];
  #   };
  #
  #   config = lib.mkIf cfg.enable (
  #     lib.installProgram {
  #       inherit programName config;
  #       extraModules = {
  #         systemd.user.services.waybar = (
  #           lib.mkIf (cfg.systemd.enable) {
  #             wantedBy = [ "graphical-session.target" ];
  #             serviceConfig = {
  #               Type = "exec";
  #               ExecStart = "${cfg.package}/bin/waybar";
  #               Restart = "on-failure";
  #               RestartSec = 5;
  #               Slice = "app.slice";
  #             };
  #             unitConfig = {
  #               After = "graphical-session.target";
  #               ConditionEnvironment = "WAYLAND_DISPLAY";
  #               Description = "waybar";
  #               Requisite = "graphical-session.target";
  #               PartOf = "graphical-session.target";
  #             };
  #           }
  #         );
  #       };
  #     }
  #   );
}
