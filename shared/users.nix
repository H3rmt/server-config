{ lib, config, home, pkgs, inputs, ... }:
let
  clib = import ./funcs.nix { inherit lib; inherit config; };
  age = config.age;
  hostName = config.networking.hostName;
in
{
  users.users.root = {
    openssh = {
      authorizedKeys.keys = [
        config.my-public-key
        config.server.main-1.public-key
        config.server.main-2.public-key
        config.server.raspi-1.public-key
      ];
    };
    isSystemUser = true;
    hashedPasswordFile = age.secrets.root_pass.path;
  };
  users.users."${config.backup-user-prefix}-${hostName}" = {
    openssh = {
      authorizedKeys.keys = [
        config.server.main-1.public-key-borg
        config.server.main-2.public-key-borg
        config.server.raspi-1.public-key-borg
      ];
    };
    createHome = true;
    isNormalUser = true;
    shell = pkgs.zsh;
    linger = true;
  };
  users.users."${config.exporter-user-prefix}-${hostName}" = {
    createHome = true;
    isNormalUser = true;
    shell = pkgs.zsh;
    linger = true;
    extraGroups = [ "systemd-journal" ];
  };

  home-manager.users."${config.exporter-user-prefix}-${hostName}" = import ./users/exporter.nix { inherit age; inherit clib; inherit hostName; };
  home-manager.users."${config.backup-user-prefix}-${hostName}" = import ./users/backup.nix { inherit age; inherit clib; inherit hostName; };
  home-manager.users.root = import ./users/root.nix { inherit age; inherit clib; };
}
