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
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3IVwWPgIK0goGqR7IoN9OE/TuAKHrXLZPOkByWdOII"
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
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.filesharing = import ./filesharing.nix { age = config.age; inherit clib; mconfig = config; };
}
