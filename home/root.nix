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
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

  programs.git = {
  	enable = true;
  	userName = "Enrico Stemmer";
	userEmail = "stemmer.enrico@gmail.com";
  };
}
