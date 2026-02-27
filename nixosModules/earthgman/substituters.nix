{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.substituters;
in
{
  options.earthgman.substituters = {
    "nix-store.earthgman.dev" = {
      enable = lib.mkEnableOption ''
        trust for https://nix-store.earthgman.dev as a source for prebuilt packages.
        This is a personally owned server and thus you have the option to disable it if you are paranoid
      '';
      publicKey = lib.mkOption {
        description = "public key of the server";
        type = lib.types.str;
        default = "nix-store.earthgman.dev:2Qrw9kS+K2c00ikcgaz5Y0M7j5XmkhFJz3d7oNgJdLw=";
      };
    };

    "yazi.cachix.org" = {
      enable = lib.mkEnableOption "cachix for yazi-git";
      publicKey = lib.mkOption {
        description = "public key of the server";
        type = lib.types.str;
        default = "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k=";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg."nix-store.earthgman.dev".enable) {
      nix.settings = {
        substituters = [ "https://nix-store.earthgman.dev" ];
        trusted-public-keys = [ cfg.publicKey ];
      };
    })
    (lib.mkIf (cfg."yazi.cachix.org".enable) {
      nix.settings = {
        substituters = [ "https://yazi.cachix.org" ];
        trusted-public-keys = [ cfg."yazi.cachix.org".publicKey ];
      };
    })
  ];
}
