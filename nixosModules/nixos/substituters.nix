{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.substituters;
in
{
  options.substituters = lib.mkOption {
    description = "Moduleset to register and toggle trusted substituters more easily";
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options = {
            enable = lib.mkEnableOption "whether to trust this substituter";
            priority = lib.mkOption {
              description = "priority for this substituter cache (lower values = higher priority)";
              type = lib.types.int;
              default = 40;
            };
            publicKey = lib.mkOption {
              description = "The public key for this substituter";
              type = lib.types.str;
              default = "";
            };
          };
        }
      )
    );
  };

  config = {
    assertions = lib.remove { } (
      lib.forEach (builtins.attrNames cfg) (
        subsituter:
        if (cfg.${subsituter}.enable && cfg.${subsituter}.publicKey == "") then
          {
            assertion = false;
            message = "substituter ${subsituter} is enabled but has no public key associated with it!";
          }
        else
          { }
      )
    );

    nix.settings = {
      substituters = lib.remove "" (
        lib.forEach (builtins.attrNames cfg) (
          substituter:
          let
            priority = "?priority=${toString cfg.${substituter}.priority}";
          in
          if (cfg.${substituter}.enable) then "https://" + substituter + priority else ""
        )
      );
      trusted-public-keys = lib.remove "" (
        lib.forEach (builtins.attrValues cfg) (
          substituter: if (substituter.enable) then substituter.publicKey else ""
        )
      );
    };
  };
}
