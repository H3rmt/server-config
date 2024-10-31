{ lib, config, home, pkgs, clib, mainConfig, inputs, ... }:
let
  #   TOR_VERSION = "v0.3.6-exporter";
in
{
  imports = [
    ../../shared/baseuser.nix
  ];
}
