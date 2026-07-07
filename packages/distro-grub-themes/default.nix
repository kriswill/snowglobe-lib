{
  lib,
  stdenvNoCC,
  fetchurl,
  distro ? "nixos",
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "distro-grub-themes";
  version = "3.2";
  src = fetchurl {
    url = "https://github.com/AdisonCavani/distro-grub-themes";
    hash = "sha256-RnN8fPmMlcTXQBcygFwGLppIs6IlobFMQYGNL+JZi2k=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out
    runHook postInstall
  '';
}
