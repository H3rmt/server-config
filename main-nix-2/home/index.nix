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
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKIpoY7xkKbUMJ1/Fg1jPu1jwQzfXgjvybcsXnbI0eM"
        ];
      };
      isSystemUser = true;
      hashedPasswordFile = config.age.secrets.root_pass.path;
    };
    reverseproxy = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
    };
  };


  services.borgbackup.jobs."user-data" = {
    paths = [
      "/home/reverseproxy/${config.data-dir}"
    ];
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat '${config.age.secrets.borg_pass.path}'";
    };
    environment.BORG_RSH = "ssh -i /etc/ssh/ssh_host_ed25519_key";
    repo = ''ssh://root@${config.main-nix-1-private-ip}:${toString config.ports.public.ssh}/root/backups/main-nix-2'';
    compression = "auto,zstd,15";
    startAt = "daily";
    user = "root";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.reverseproxy = import ./reverseproxy.nix { age = config.age; inherit clib; mconfig = config; };
}
