# optional modules which will be enabled based on responses in the installer
{ lib, ... }:
{
  imports = lib.autoImport ./. { };
}
