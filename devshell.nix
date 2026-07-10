{ flake, pkgs }:
let
  lib = pkgs.lib;
  stdenv = pkgs.stdenv;
  system = stdenv.hostPlatform.system;
  snowglobe-rebuild = flake.outputs.packages.${system}.snowglobe-rebuild;
  ci-sh = pkgs.runCommandLocal "snowglobe-lib-ci" { } ''
    mkdir -p $out/bin
    cp ${flake + "/lib/scripts/ci.sh"} $out/bin/ci.sh
  '';
  nix-formatter = flake.outputs.formatter.${system};

  # nixos-rebuild-ng propagates its own bundled `nix` onto PATH ahead of
  # whatever nix.package the system actually uses (e.g. Determinate Nix),
  # so the wrong nix ends up handling every `nix` invocation in this shell.
  # Drop it from the front of PATH here; it's re-added as a shellHook
  # fallback below, after the system's ambient nix.
  nixos-rebuild = pkgs.nixos-rebuild.overrideAttrs (old: {
    propagatedBuildInputs = builtins.filter (
      p: (p.outPath or null) != pkgs.nix.outPath
    ) (old.propagatedBuildInputs or [ ]);
  });
in
{

  default = pkgs.mkShell {
    shellHook = ''
      echo Activated devshell
      echo You can now run ci.sh
      export SNOWGLOBE_DEVSHELL=1
      export PATH="$PATH:${lib.makeBinPath [ pkgs.nix ]}"
    '';

    packages = [
      ci-sh
      snowglobe-rebuild
      nix-formatter
      pkgs.openssh
      nixos-rebuild
      pkgs.gnupg
      pkgs.fzf
      pkgs.git
      pkgs.nix-output-monitor
      pkgs.libnotify
      pkgs.nvd
      pkgs.nh
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      pkgs.systemd
      pkgs.iputils
    ];
  };
}
