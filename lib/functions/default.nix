{ flake }:
let
  lib = flake.inputs.nixpkgs.lib;
  flake-helpers = import ./flake-helpers { inherit flake; };
  module-wrappers = import ./module-wrappers { inherit flake lib; };
in
flake-helpers // module-wrappers
