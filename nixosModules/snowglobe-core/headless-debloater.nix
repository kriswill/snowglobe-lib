# used to debloat headless systems
{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.snowglobe-core.headless-debloater.enable = lib.mkEnableOption "Snowglobe-Core's nixos debloater for headless systems";

  config = lib.mkIf config.snowglobe-core.headless-debloater.enable {
    # disables linux firmware by default since most servers or headless machines, especially vms, dont need firmware from it.
    hardware.enableRedistributableFirmware = lib.mkOverride 899 false;

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
