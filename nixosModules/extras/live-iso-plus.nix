{
  pkgs,
  lib,
  config,
  ...
}:
{
  gman.dotfile-deps.enable = true;
  gman.hacker-mode.enable = true;
  gman.display-manager.enable = false;
  services.xserver.displayManager.lightdm.enable = false;

  # nixos removes fonts for live images
  fonts.fontconfig.enable = true;
}
