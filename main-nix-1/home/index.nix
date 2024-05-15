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
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAz2IRRlU5CN8TRnHnHD98R5CWSGHQBg9hxqeYARdoK"
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

  services.borgbackup.jobs."user-data" = {
    paths = [
      "/home/filesharing/${config.data-dir}"
    ];
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat '${config.age.secrets.borg_pass.path}'";
    };
    environment.BORG_RSH = "ssh -i /etc/ssh/ssh_host_ed25519_key";
    repo = ''ssh://root@${config.main-nix-2-private-ip}:${toString config.ports.public.ssh}/root/backups/main-nix-1'';
    compression = "auto,zstd,15";
    startAt = "*:0,10,20,30,40,50";
    user = "root";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.filesharing = import ./filesharing.nix { age = config.age; inherit clib; mconfig = config; };
}
