{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-core.substituters;
in
{
  options.snowglobe-core.substituters = {
    "nix-store.snowglobe-core.dev" = {
      enable = lib.mkEnableOption ''
        trust for https://nix-store.snowglobe-core.dev as a source for prebuilt packages.
        This is a personally owned server and thus you have the option to disable it if you are paranoid
      '';
      publicKey = lib.mkOption {
        description = "public key of the server";
        type = lib.types.str;
        default = "nix-store.snowglobe-core.dev:2Qrw9kS+K2c00ikcgaz5Y0M7j5XmkhFJz3d7oNgJdLw=";
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
    (lib.mkIf (cfg."nix-store.snowglobe-core.dev".enable) {
      nix.settings = {
        substituters = [ "https://nix-store.snowglobe-core.dev" ];
        trusted-public-keys = [ cfg."nix-store.snowglobe-core.dev".publicKey ];
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
