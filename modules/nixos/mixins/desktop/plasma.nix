{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.desktop.plasma;
in
{
  options.gman.desktop.plasma.enable = lib.mkEnableOption "gman's plasma 6 configuration";

  config = lib.mkIf cfg.enable {
    system.activationScripts = {
      fix-plasma-icons = pkgs.writeShellScript "fix-plasma-icons" (
        builtins.readFile ../../../../scripts/fix-plasma-icons.sh
      );
    };

    gman.sddm.enable = false; # kde does not play well with this module

    # make sure plasma can manage the QT configuration independent of nix
    qt.platformTheme = lib.mkOverride 899 null;
    qt.style = lib.mkOverride 899 null;

    services = {
      desktopManager.plasma6 = {
        enable = true;
      };

      # ensure sddm is enabled
      displayManager.sddm.enable = true;
    };

    environment = {
      systemPackages = [ pkgs.wl-clipboard ];
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
      kalk.enable = true;
      gnome-calculator.enable = lib.mkOverride 899 false;

      # disable the default gnome frontend in favor of KDE discover
      gnome-software.enable = lib.mkOverride 899 false;

      # disable pwvucontrol in favor of the default plasma volume control
      pwvucontrol.enable = lib.mkOverride 899 false;
    };
  };
}
