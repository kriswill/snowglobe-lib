{
  #   pkgs,
  #   config,
  #   lib,
  #   ...
  # }:
  # let
  #   cfg = config.gman.desktop.gnome;
  # in
  # {
  #   options.gman.desktop.gnome = {
  #     enable = lib.mkEnableOption "custom gnome module";
  #     withDefaultPackages = lib.mkEnableOption "gnome's bloatware";
  #   };
  #   config = lib.mkIf cfg.enable (
  #     lib.mkMerge [
  #       {
  #         services.desktopManager.gnome.enable = true;
  #
  #         services.displayManager = {
  #           sddm.enable = lib.mkOverride 800 false;
  #           gdm.enable = lib.mkOverride 800 true;
  #         };
  #
  #         # qplatformgnome has failed to build in configurephase 10-10-2025
  #         qt.platformTheme = lib.mkForce "qt5ct";
  #       }
  #       (lib.mkIf (!cfg.withDefaultPackages) {
  #         # exclude all packages built into gnome and allow each user to choose what they want installed
  #         # lib.mkOverride 800 required due to stock nixos gnome module
  #         programs.geary.enable = lib.mkOverride 800 false;
  #         programs.evince.enable = lib.mkOverride 800 false;
  #         programs.seahorse.enable = lib.mkOverride 800 false;
  #         environment.gnome.excludePackages = builtins.attrValues {
  #           inherit (pkgs)
  #             gnome-tour
  #             simple-scan
  #             baobab
  #             file-roller
  #             gedit
  #             hexchat
  #             loupe
  #             snapshot
  #             decibels
  #             nautilus
  #             gnome-connections
  #             gnome-text-editor
  #             gnome-terminal
  #             gnome-system-monitor
  #             gnome-calendar
  #             gnome-weather
  #             gnome-music
  #             gnome-characters
  #             gnome-clocks
  #             #gnome-camera
  #             gnome-calculator
  #             gnome-maps
  #             gnome-contacts
  #             gnome-initial-setup
  #             gnome-font-viewer
  #             gnome-disk-utility
  #             gnome-remote-desktop
  #             #gnome-online-miners
  #             gnome-logs
  #             cheese
  #             epiphany
  #             tali
  #             iagno
  #             hitori
  #             atomix
  #             totem
  #             yelp
  #             ;
  #         };
  #       })
  #     ]
  #   );
}
