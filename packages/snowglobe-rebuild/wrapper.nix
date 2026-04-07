{
  lib,
  makeWrapper,
  symlinkJoin,
  snowglobe-rebuild-unwrapped,
  gitMinimal,
}:
let
  runtimeDeps = [
    gitMinimal
  ];
in
symlinkJoin {
  name = "snowglobe-rebuild";
  nativeBuildInputs = [ makeWrapper ];

  paths = [ snowglobe-rebuild-unwrapped ];

  postBuild = ''
    wrapProgram $out/bin/snowglobe-rebuild \
      --suffix PATH : ${lib.makeBinPath runtimeDeps}
  '';
}
