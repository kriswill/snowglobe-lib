{ lib, ... }:
dir:
let
  fileNames = builtins.attrNames (builtins.readDir dir);
  strippedFileNames = lib.filter (name: name != "default.nix") fileNames;
in
lib.forEach (strippedFileNames) (fileName: dir + /${fileName})
