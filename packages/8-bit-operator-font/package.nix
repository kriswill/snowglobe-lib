{ pkgs, stdenvNoCC, ... }:
let
  name = "_8-bit-operator-font";
in
stdenvNoCC.mkDerivation {
  inherit name;
  pname = name;

  src = builtins.fetchurl {
    url = "https://www.earthgman.dev/fonts/8-bit-operator.zip";
    sha256 = "48c3763eb3dad4496bec6597013fb2940243e0fd149d1d1ad39f2561c1012817";
  };
  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/share/fonts
    ${pkgs.unzip}/bin/unzip $src -d $out/share/fonts 
  '';
}
