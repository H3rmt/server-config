{ lib
, config
, home
, pkgs
, ...
}: {
  imports = [
    ../vars.nix
    ../zsh.nix
  ];
  home.stateVersion = config.nixVersion;
}
