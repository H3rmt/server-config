let
  main = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKIpoY7xkKbUMJ1/Fg1jPu1jwQzfXgjvybcsXnbI0eM";
  my = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t";
in
{
  "borg_pass.age".publicKeys = [ main my ];
  "root_pass.age".publicKeys = [ main my ];
  "filesharing/admin_pass.age".publicKeys = [ main my ];
  "filesharing/admin_email.age".publicKeys = [ main my ];
  "nextcloud/maria_root_pass.age".publicKeys = [ main my ];
  "nextcloud/maria_pass.age".publicKeys = [ main my ];
}
