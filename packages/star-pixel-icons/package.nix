{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  unstableGitUpdater,
  hicolor-icon-theme,
  adwaita-icon-theme,
  gtk3,
}:

stdenvNoCC.mkDerivation {
  pname = "star-pixel-icons";
  version = "03.09.2025";

  src = fetchFromGitHub {
    owner = "Starciad";
    repo = "star-pixel-icons-theme";
    rev = "44625afc5ee831f1513d6687c601d4805892129c";
    hash = "sha256-XDAWlCbdVAC74qZ/E1sok9jRkB0yForhQnVVg1WYnQc=";
  };

  nativeBuildInputs = [ gtk3 ];

  propagatedBuildInputs = [
    hicolor-icon-theme
    adwaita-icon-theme
  ];

  dontDropIconThemeCache = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons/star-pixel-icons
    cp -r src/SPI/* $out/share/icons/star-pixel-icons
    gtk-update-icon-cache $out/share/icons/star-pixel-icons

    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    homepage = "https://github.com/Starciad/star-pixel-icons";
    description = "Starciad's pixel icon theme for linux";
    license = lib.licenses.cc-by-sa-40;
    platforms = lib.platforms.linux;
    maintainers = [ lib.maintainers.EarthGman ];
  };
}
