{ lib
, config
, pkgs
, ...
}:
let
  clib = import ../funcs.nix { inherit lib; inherit config; };
in
{
  imports = [
    ../secret-vars.nix
  ];

  users.users = {
    root = {
      openssh = {
        authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t" ];
      };
      isSystemUser = true;
    };
    reverseproxy = {
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
    authentik = {
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
    nextcloud = {
      createHome = true;
      isNormalUser = true;
      shell = pkgs.zsh;
      linger = true;
    };
  };

  home-manager.users.root = import ./root.nix;
  home-manager.users.reverseproxy = import ./reverseproxy.nix { age = config.age; inherit clib; };
  home-manager.users.grafana = import ./grafana.nix { age = config.age; inherit clib; };
  home-manager.users.authentik = import ./authentik.nix { age = config.age; inherit clib; };
  home-manager.users.snowflake = import ./snowflake.nix { age = config.age; inherit clib; };
  home-manager.users.nextcloud = import ./nextcloud.nix { age = config.age; inherit clib; };
}
