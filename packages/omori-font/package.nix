{ stdenvNoCC, ... }:
let
  name = "omori-font";
in
stdenvNoCC.mkDerivation {
  inherit name;
  pname = name;

  src = builtins.fetchurl {
    url = "https://www.earthgman.dev/assets/fonts/omori-2.ttf";
    sha256 = "e050e8683bcbbb4a2e60afa50fab9892e95507f25d8439fb37d3a2eca90fd0c2";
  };
  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/share/fonts
    cp $src $out/share/fonts/omori-2.ttf
  '';
}
