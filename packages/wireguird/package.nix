{
  lib,
  buildGoModule,
  fetchFromGitHub,
  libayatana-appindicator,
  pkg-config,
  wrapGAppsHook3,
  gtk3,
  wireguard-tools,
  openresolv,
}:

buildGoModule rec {
  pname = "wireguird";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "UnnoTed";
    repo = "wireguird";
    rev = "v${version}";
    hash = "sha256-iv0/HSu/6IOVmRZcyCazLdJyyBsu5PyTajLubk0speI=";
  };

  vendorHash = "sha256-/MeaomhmQL3YNrR4a0ihGwZAo5Zk8snpJvCSXY93aM8=";

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    wireguard-tools
    libayatana-appindicator
    openresolv
  ];

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "Wireguard gtk gui for linux";
    homepage = "https://github.com/UnnoTed/wireguird";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.EarthGman ];
    mainProgram = "wireguird";
  };
}
