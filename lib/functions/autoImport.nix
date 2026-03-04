{ lib, ... }:
dir:
{
  exceptions ? [ ],
}:
let
  fileNames = builtins.attrNames (builtins.readDir dir);
  strippedFileNames = lib.filter (
    name: name != "default.nix" && !(builtins.elem name exceptions)
  ) fileNames;
in
lib.forEach (strippedFileNames) (fileName: dir + /${fileName})
