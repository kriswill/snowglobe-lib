{
  inputs,
  outputs,
  lib,
  ...
}:
{
  # wrapper for lib.nixosSystem
  mkNixosHost = import ./mkNixosHost.nix {
    inherit
      inputs
      outputs
      lib
      ;
  };
}
