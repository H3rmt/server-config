{ lib
, config
, pkgs
, ...
}:
let
  clib = import ../../funcs.nix { inherit lib; inherit config; };
in
{
  imports = [
    ./root.nix
  ];

  users.mutableUsers = false;
  users.defaultUserShell = pkgs.zsh;
  users.users = {
    root = {
      openssh = {
        authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKIpoY7xkKbUMJ1/Fg1jPu1jwQzfXgjvybcsXnbI0eM"
        ];
      };
      isSystemUser = true;
    };
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
}
