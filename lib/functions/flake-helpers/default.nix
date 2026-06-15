{
  flake,
  lib,
  ...
}:
{
  # wrapper for lib.nixosSystem
  mkNixosHost = import ./mkNixosHost.nix {
    inherit
      flake
      lib
      ;
  };
}
