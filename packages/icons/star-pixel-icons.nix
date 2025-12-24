{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  unstableGitUpdater,
  gtk3,
}:

stdenvNoCC.mkDerivation {
  pname = "star-pixel-icons";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "Starciad";
    repo = "star-pixel-icons-theme";
    rev = "44625afc5ee831f1513d6687c601d4805892129c";
    hash = "sha256-XDAWlCbdVAC74qZ/E1sok9jRkB0yForhQnVVg1WYnQc=";
  };

  nativeBuildInputs = [ gtk3 ];

  dontDropIconThemeCache = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons/star-pixel-icons
    cp -r src/SPI/* $out/share/icons/star-pixel-icons
    gtk-update-icon-cache $out/share/icons/star-pixel-icons

    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = with lib; {
    homepage = "https://github.com/Starciad/star-pixel-icons";
    description = "Starciad's pixel icon theme for linux";
    license = licenses.cc-by-sa-40;
    platforms = platforms.linux;
    maintainers = with maintainers; [ EarthGman ];
  };
}
