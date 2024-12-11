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
    puppeteer-sma = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
    };
  };

  home-manager.users.filesharing = import ./filesharing.nix;
  home-manager.users.nextcloud = import ./nextcloud.nix;
  home-manager.users.bridge = import ./bridge.nix;
  home-manager.users.snowflake = import ./snowflake.nix;
  home-manager.users.puppeteer-sma = import ./puppeteer-sma.nix;
}
