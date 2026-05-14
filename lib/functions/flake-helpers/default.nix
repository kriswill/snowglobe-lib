{
  self,
  inputs,
  outputs,
  lib,
  ...
}:
{
  # wrapper for lib.nixosSystem
  mkNixosHost = import ./mkNixosHost.nix {
    inherit
      self
      inputs
      outputs
      lib
      ;
  };
}
