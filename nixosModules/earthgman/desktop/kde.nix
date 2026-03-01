{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.desktop.kde;
in
{
  options.earthgman.desktop.kde.enable = lib.mkEnableOption "EarthGman's KDE plasma module";

  config = lib.mkIf cfg.enable {
    # script which will repair imperative icons pinned to taskbar and desktop by users
    system.userActivationScripts = {
      fix-plasma-icons.text = ''
        # script that will repair KDE plasma icons after a flake update.
        # Instead of referencing icons at the correct location /run/current-system/sw/share/applications, Freaking kde plasma just references the /nix/store directly for some reason.
        # On NixOS (if you do not use home-manager) you should NEVER have files in your home directory that reference the /nix/store directly ever.
        # Every time the NAR hashes of the store update, the imperatively created links will not update by default.
        # This causes the icons on KDE plasma to disappear because they now reference a store path that doesn't exist.

        # fix icons on the taskbar
        ${pkgs.gnused}/bin/sed -i 's/\/nix\/store\/[A-Za-z0-9]\+-system-path\/share\/applications/\/run\/current-system\/sw\/share\/applications/g' "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

        # Fix symlinks in /home/user/Desktop
        DESKTOP_DIR="$HOME/Desktop"
        for file in "$DESKTOP_DIR"/*; do
          CURRENT_FILE="$DESKTOP_DIR/$file"
          case "$(readlink "$CURRENT_FILE")" in
            "/nix/store"*)
              rm "$CURRENT_FILE"
              ln -s "/run/current-system/sw/share/applications/$file" "$CURRENT_FILE"
              ;;
            *)
              continue
              ;;
            esac
          done
      '';
    };

    earthgman = {
      display-manager.enable = false; # allow kde to use its own display-manager config
      flatpak-config.enable = false; # let kde take care of this too
    };

    # make sure plasma can manage the QT configuration independent of nix
    qt.platformTheme = lib.mkOverride 899 null;
    qt.style = lib.mkOverride 899 null;

    services = {
      blueman.enable = false;
      desktopManager.plasma6 = {
        enable = true;
      };
    };

    environment = {
      # needed for some scripts and applications
      plasma6.excludePackages = builtins.attrValues {
        inherit (pkgs.kdePackages)
          elisa
          khelpcenter
          kinfocenter
          ;
      };
    };

    # plasma does not come with a calculator
    programs = {
      wl-clipboard.enable = true; # needed for some stuff
      gnome-calculator.enable = lib.setDefault true; # kde does not come with a calculator

      # disable pwvucontrol in favor of the default plasma volume control
      pwvucontrol.enable = lib.mkDefault false;
    };
  };
}
