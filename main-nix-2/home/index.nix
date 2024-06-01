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
    authentik = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
    };
    grafana = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
    };
    node-exporter-2 = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
      extraGroups = [ "systemd-journal" ];
    };
    tor = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
    };
    wakapi = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
    };
    "${config.backup-user}" = {
      openssh = {
        authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKIpoY7xkKbUMJ1/Fg1jPu1jwQzfXgjvybcsXnbI0eM"
        ];
      };
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = false;
    };
  };

  services.borgbackup.jobs."user-data" = {
    paths = [
      "/home/reverseproxy/${config.data-dir}"
      "/home/authentik/${config.data-dir}"
      "/home/grafana/${config.data-dir}"
      "/home/tor/${config.data-dir}"
      "/home/wakapi/${config.data-dir}"
    ];
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat '${config.age.secrets.borg_pass.path}'";
    };
    environment.BORG_RSH = "ssh -i /etc/ssh/ssh_host_ed25519_key";
    repo = ''ssh://${config.backup-user}@${config.main-nix-1-private-ip}:${toString config.ports.exposed.ssh}/home/${config.backup-user}/backups/main-nix-2'';
    compression = "auto,zstd,15";
    startAt = "*:0,30";
    user = "${config.backup-user}";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.reverseproxy = import ./reverseproxy.nix { age = config.age; inherit clib; };
  home-manager.users.authentik = import ./authentik.nix { age = config.age; inherit clib; };
  home-manager.users.grafana = import ./grafana.nix { age = config.age; inherit clib; };
  home-manager.users.node-exporter-2 = import ./node-exporter-2.nix { age = config.age; inherit clib; };
  home-manager.users.tor = import ./tor.nix { age = config.age; inherit clib; };
  home-manager.users.wakapi = import ./wakapi.nix { age = config.age; inherit clib; };
}
