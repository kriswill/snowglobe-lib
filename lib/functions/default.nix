{
  self,
  inputs,
  outputs,
  lib,
}:
let
  flake-helpers = import ./flake-helpers {
    inherit
      self
      inputs
      outputs
      lib
      ;
  };

  module-wrappers = import ./module-wrappers { inherit lib; };
in
flake-helpers // module-wrappers
