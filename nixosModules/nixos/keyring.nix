# provide a core module which allows storage and easy configuration of public keys in one place
{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.keyring = {
    ssh = lib.mkOption {
      description = "public ssh keys for ease of access throughout your config.";
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };

    substitutors = lib.mkOption {
      description = "public keys from trusted nix substitutors";
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };

    openpgp = lib.mkOption {
      description = "public keys for openpgp";
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };

    age = lib.mkOption {
      description = "age public keys";
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };
}
