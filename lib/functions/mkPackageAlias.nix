{
  lib,
}:
{
  program,
  alias,
  package,
  pkgs,
}:
pkgs.symlinkJoin {
  name = "${alias}->${program}";
  paths = [ package ];

  postBuild = ''
    rm -f $out/bin/${program}-alias
    ln -s $out/bin/${program} $out/bin/${alias}
  '';
}
