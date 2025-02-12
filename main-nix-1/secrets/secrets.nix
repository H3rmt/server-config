let
  main = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKIpoY7xkKbUMJ1/Fg1jPu1jwQzfXgjvybcsXnbI0eM";
  my = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t";
in
{
  "borg/main-nix-1.age".publicKeys = [ main my ];
  "borg/main-nix-2.age".publicKeys = [ main my ];
  "borg/raspi-1.age".publicKeys = [ main my ];
  "root_pass.age".publicKeys = [ main my ];
  "wireguard_private.age".publicKeys = [ main my ];
  "filesharing/admin_pass.age".publicKeys = [ main my ];
  "filesharing/admin_email.age".publicKeys = [ main my ];
  "nextcloud/maria_root_pass.age".publicKeys = [ main my ];
  "nextcloud/maria_pass.age".publicKeys = [ main my ];
  "nextcloud/admin_pass.age".publicKeys = [ main my ];
}
