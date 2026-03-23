{
  inputs,
  outputs,
  lib,
  ...
}:
{
  # automatically wrap your modules into a list that can be passed to imports
  autoImport = import ./autoImport.nix { inherit lib; };

  # custom program option framework
  mkProgramOption = import ./mkProgramOption.nix { inherit lib; };
  installProgram = import ./installProgram.nix { inherit lib; };

  # creating user units bound to desktop sessions
  mkGraphicalService = import ./mkGraphicalService.nix { inherit lib; };

  # wrapper for lib.nixosSystem
  mkNixosHost = import ./mkNixosHost.nix { inherit inputs outputs lib; };

  # making aliases for programs
  mkProgramAlias = import ./mkProgramAlias.nix { inherit lib; };

  # lib.mkOverride function but with an even weaker value than lib.mkDefault
  setDefault = object: lib.mkOverride 1337 object;
}
