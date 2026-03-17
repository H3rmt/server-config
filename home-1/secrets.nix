{ ... }:
{
  age.secrets.wireguard_private.rekeyFile = ./secrets/wireguard_private.age;
  age.secrets.wireguard_private.group = "systemd-network";
  age.secrets.wireguard_private.mode = "640";
}
