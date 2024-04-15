{ lib
, config
, home
, ...
}: {
  imports = [
    ../vars.nix
    ../varsmodule.nix
  ];
  home.stateVersion = config.vars.nixVersion;
  programs.zsh = import ../zsh.nix { };
}
