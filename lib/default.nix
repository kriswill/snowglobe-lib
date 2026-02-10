{
  inputs,
  outputs,
  lib,
}:
{
  autoImport = import ./functions/autoImport.nix { inherit lib; };
  mkHost = import ./functions/mkHost.nix { inherit inputs outputs; };
  mkProgramOption = import ./functions/mkProgramOption.nix { inherit lib; };
}
