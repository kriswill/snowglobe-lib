{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
  cfg = config.snowglobe-lib.desktop.kde;
in
{
  options.snowglobe-lib.desktop.kde.enable = lib.mkEnableOption "Snowglobe-Lib's KDE plasma module";

  config = lib.mkIf cfg.enable {
    snowglobe-lib = {
      system.hasDesktop = lib.mkForce true;
      desktop = {
        enable = true;
        installWaylandDeps = true;
      };
    };
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
          FILE_NAME=$(printf "$file" | rev | cut -d/ -f1 | rev)
          case "$(readlink "$file")" in
            "/nix/store"*)
              rm "$file"
              ln -s "/run/current-system/sw/share/applications/$FILE_NAME" "$file"
              ;;
            *)
              continue
              ;;
            esac
          done
      '';
    };

    # make sure plasma can manage the QT configuration independent of nix
    qt.platformTheme = lib.mkOverride 899 null;
    qt.style = lib.mkOverride 899 null;

    services = {
      # use builtin plasma bluetooth
      blueman.enable = false;

      # use sddm
      displayManager.ly.enable = false;

      flatpak.enable = slib.setDefault true;

      desktopManager.plasma6 = {
        enable = true;
      };
    };

    environment = {
      plasma6.excludePackages = builtins.attrValues {
        inherit (pkgs.kdePackages)
          khelpcenter
          kinfocenter
          ;
      };
    };

    # plasma does not come with a calculator
    programs = {
      wl-clipboard.enable = true; # needed for some stuff
      gnome-calculator.enable = slib.setDefault true; # kde does not come with a calculator

      # disable pwvucontrol in favor of the default plasma volume control
      pwvucontrol.enable = lib.mkDefault false;
    };
  };
}
