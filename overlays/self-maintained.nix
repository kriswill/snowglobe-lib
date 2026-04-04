{
  lib,
}:
let
  packages = lib.filter (name: name != "default.nix") (
    builtins.attrNames (builtins.readDir ../packages/self-maintained)
  );
  createOverlays =
    packages: numPackages:
    let
      package = builtins.elemAt packages (numPackages - 1);
      overlayName = "${package}-git";
    in
    if (numPackages == 1) then
      { ${overlayName} = final: prev: (import ../packages/self-maintained/${package} { pkgs = final; }); }
    else
      ({ ${overlayName} = final: prev: import ../packages/self-maintained/${package} { pkgs = final; }; })
      // (createOverlays packages (numPackages - 1));
in
createOverlays packages (builtins.length packages)
