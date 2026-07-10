{
  flake,

  lib,
  runCommandLocal,
  symlinkJoin,
  makeWrapper,
  gitMinimal,
  fzf,
  nvd,
  dash,
}:
let
  snowglobe-rebuild-unwrapped = runCommandLocal "snowglobe-rebuild-unwrapped" { } ''
    mkdir -p $out/bin
    cp ${flake + "/lib/scripts/snowglobe-rebuild.sh"} $out/bin/snowglobe-rebuild
    substituteInPlace $out/bin/snowglobe-rebuild \
      --replace-fail '#!/bin/sh' '#!${lib.getExe dash}'
  '';

  runtimePackages = [
    gitMinimal
    fzf
    nvd
  ];
in
symlinkJoin {
  name = "snowglobe-rebuild";
  paths = [ snowglobe-rebuild-unwrapped ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/snowglobe-rebuild \
      --suffix PATH : ${lib.makeBinPath runtimePackages}
  '';
}
