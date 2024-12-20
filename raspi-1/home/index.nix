{ lib, config, pkgs, ... }:
let
  clib = import ../../shared/funcs.nix { inherit lib; inherit config; };
in
{
  imports = [
    ../../shared/users.nix
  ];

  users.mutableUsers = true;
  users.defaultUserShell = pkgs.zsh;
  users.users = {
    kiosk = {
      openssh = {
        authorizedKeys.keys = [
          config.server."${config.hostnames.main-1}".root-public-key
        ];
      };
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
      extraGroups = [ "tty" ];
    };
  };

  home-manager.users.kiosk = import ./kiosk.nix;
}
