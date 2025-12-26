{
  lib,
  python3Packages,
  fetchFromGitHub,
  ...
}:

python3Packages.buildPythonPackage rec {
  pname = "mov-cli-youtube";
  version = "1.3.11";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "mov-cli";
    repo = "mov-cli-youtube";
    rev = "${version}";
    hash = "sha256-H+00f/0+zVY9KXbVwxCN3FjlRO1/maOdfZvLoNRAMzc=";
  };

  dependencies = with python3Packages; [
    setuptools
    pytubefix
    requests
    yt-dlp
  ];

  meta = with lib; {
    description = "Youtube plugin for mov-cli";
    homepage = "https://github.com/mov-cli/mov-cli-youtube";
    license = licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    maintainers = [ lib.maintainers.EarthGman ];
  };
}
