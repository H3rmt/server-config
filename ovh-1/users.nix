{ lib, config, pkgs, ... }: {
  imports = [
    ../shared/users.nix
  ];

  users.mutableUsers = false;
  users.defaultUserShell = pkgs.zsh;
  users.users = {
    reverseproxy = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
    };
  };

  home-manager.users.reverseproxy = import ./home/reverseproxy.nix;
}
