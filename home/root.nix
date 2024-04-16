{ lib
, config
, home
, pkgs
, ...
}: {
  imports = [
    ../vars.nix
    ../varsmodule.nix
    ../zsh.nix
  ];
  home.stateVersion = config.vars.nixVersion;
}
