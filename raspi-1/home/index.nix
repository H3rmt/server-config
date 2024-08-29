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
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
      extraGroups = [ "tty" ];
    };
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.kiosk = import ./kiosk.nix { age = config.age; inherit clib; };
}
