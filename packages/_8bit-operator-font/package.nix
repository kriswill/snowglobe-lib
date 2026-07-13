{
  unzip,
  lib,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "_8bit-operator-font";
  # TODO find actual version
  version = "1.0";

  src = builtins.fetchurl {
    url = "https://www.earthgman.dev/assets/fonts/8-bit-operator.zip";
    sha256 = "sha256:05r8070n29czscd1v78lzph460lln8zh35v5ximlkm6sncz7dhs8";
  };

  phases = [ "installPhase" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts
    ${unzip}/bin/unzip $src -d $out/share/fonts

    runHook postInstall
  '';

  meta = {
    description = "8bit Operator font";
    homepage = "https://www.1001freefonts.com/8-bit-operator.font";
    maintainers = [ lib.maintainers.EarthGman ];
    licenses = [
      lib.licenses.gpl3
      lib.licenses.ofl
      lib.licenses.publicDomain
    ];
  };
}
