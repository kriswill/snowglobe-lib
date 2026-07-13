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
    url = "https://www.1001freefonts.com/d/14007/8-bit-operator.zip";
    sha256 = "48c3763eb3dad4496bec6597013fb2940243e0fd149d1d1ad39f2561c1012817";
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
