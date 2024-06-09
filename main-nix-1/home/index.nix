{ lib, config, pkgs, ... }:
let
  clib = import ../../shared/funcs.nix { inherit lib; inherit config; };
in
{
  imports = [
    ../../shared/users.nix
  ];

  users.mutableUsers = false;
  users.defaultUserShell = pkgs.zsh;
  users.users = {
    filesharing = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
    };
    nextcloud = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
    };
    bridge = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
    };
    snowflake = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
    };
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.filesharing = import ./filesharing.nix { age = config.age; inherit clib; };
  home-manager.users.nextcloud = import ./nextcloud.nix { age = config.age; inherit clib; };
  home-manager.users.bridge = import ./bridge.nix { age = config.age; inherit clib; };
  home-manager.users.snowflake = import ./snowflake.nix { age = config.age; inherit clib; };
}
