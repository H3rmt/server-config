{ lib, config, home, pkgs, inputs, ... }:
let
  clib = import ./funcs.nix { inherit lib; inherit config; };
in
{
  users.users.root = {
    openssh = {
      authorizedKeys.keys = [
        config.my-public-key
        config.server."${config.hostnames.main-1}".root-public-key
        config.server."${config.hostnames.main-2}".root-public-key
        config.server."${config.hostnames.raspi-1}".root-public-key
      ];
    };
    isSystemUser = true;
    hashedPasswordFile = config.age.secrets.root_pass.path;
  };
  users.users."${config.backup-user-prefix}-${config.networking.hostName}" = {
    openssh = {
      authorizedKeys.keys = [
        config.server."${config.hostnames.main-1}".root-public-key
        config.server."${config.hostnames.main-2}".root-public-key
        config.server."${config.hostnames.raspi-1}".root-public-key
      ];
    };
    createHome = true;
    isNormalUser = true;
    shell = pkgs.zsh;
    linger = true;
  };
  users.users."${config.exporter-user-prefix}-${config.networking.hostName}" = {
    createHome = true;
    isNormalUser = true;
    shell = pkgs.zsh;
    linger = true;
    extraGroups = [ "systemd-journal" ];
  };


  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {
    mainConfig = config;
    inherit clib;
  };

  home-manager.users."${config.exporter-user-prefix}-${config.networking.hostName}" = import ./users/exporter.nix;
  home-manager.users."${config.backup-user-prefix}-${config.networking.hostName}" = import ./users/backup.nix;
  home-manager.users.root = import ./users/root.nix;
}
