{ lib, ... }:
{
  # custom program option framework
  mkProgramOption = import ./mkProgramOption.nix { inherit lib; };
  installProgram = import ./installProgram.nix { inherit lib; };

  # creating user units bound to desktop sessions
  mkGraphicalService = import ./mkGraphicalService.nix { inherit lib; };

  # making aliases for programs
  mkProgramAlias = import ./mkProgramAlias.nix { inherit lib; };

  # lib.mkOverride function but with an even weaker value than lib.mkDefault
  setDefault = object: lib.mkOverride 1337 object;

  # override for setDefault. Still weaker than mkDefault
  overrideDefault = object: lib.mkOverride 1336 object;

  # one weight lower than mkDefault.
  # used to override nixpkgs mkDefaults but still allow users to set the option without conflicts
  overrideNixpkgsDefault = object: lib.mkOverride 899 object;
}
