{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.nix-cache;
in
{
  options.earthgman.nix-cache = {
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

  config = lib.mkIf cfg.enable {
    nix.settings = {
      substituters = [ "https://nix-store.earthgman.dev" ];
      trusted-public-keys = [ cfg.publicKey ];
    };
  };
}
