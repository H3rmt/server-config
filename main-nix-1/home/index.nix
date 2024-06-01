{ lib, config, pkgs, ... }:
let
  clib = import ../../shared/funcs.nix { inherit lib; inherit config; };
in
{
  imports = [
    ../../shared/root.nix
  ];

  users.mutableUsers = false;
  users.defaultUserShell = pkgs.zsh;
  users.users = {
    root = {
      openssh = {
        authorizedKeys.keys = [
          {config.keys.private}
          {config.keys.main-nix-1-public}
          {config.keys.main-nix-2-public}
        ];
      };
      isSystemUser = true;
      hashedPasswordFile = config.age.secrets.root_pass.path;
    };
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
    node-exporter-1 = {
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
    "${config.backup-user-prefix}-${config.networking.hostName}" = {
      openssh = {
        authorizedKeys.keys = [
          {config.keys.main-nix-1-public-borg}
          {config.keys.main-nix-2-public-borg}
        ];
      };
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
  home-manager.users.node-exporter-1 = import ./node-exporter-1.nix { age = config.age; inherit clib; };
  home-manager.users.bridge = import ./bridge.nix { age = config.age; inherit clib; };
}
