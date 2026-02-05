{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.gman.debloat-nixos.enable = lib.mkEnableOption "gman's nixos debloater";

  config = lib.mkIf config.gman.debloat-nixos.enable {
    # disables linux firmware by default since most servers, especially vms, dont need firmware from it.
    hardware.enableRedistributableFirmware = lib.mkOverride 800 false;

    environment = {
      defaultPackages = [ ];
      variables.BROWSER = "echo";
      stub-ld.enable = lib.mkForce false;
    };

    xdg = {
      autostart.enable = lib.mkForce false;
      icons.enable = lib.mkForce false;
      menus.enable = lib.mkForce false;
      mime.enable = lib.mkForce false;
      sounds.enable = lib.mkForce false;
    };

    documentation = {
      enable = lib.mkForce false;
      doc.enable = lib.mkForce false;
      info.enable = lib.mkForce false;
      man.enable = lib.mkForce false;
      nixos.enable = lib.mkForce false;
    };

    fonts.fontconfig.enable = lib.mkForce false;

    programs = {
      git.package = lib.mkDefault pkgs.gitMinimal;
      command-not-found.enable = lib.mkDefault false;
    };
  };
}
