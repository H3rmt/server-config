let
  main = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChc0OADBHo5eqE4tcVHglCGzUvHSTZ6LeC0RcGQ9V6C";
  my = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t";
in
{
  "borg_pass.age".publicKeys = [ main my ];
  "root_pass.age".publicKeys = [ main my ];
  "filesharing/admin_pass.age".publicKeys = [ main my ];
  "filesharing/admin_email.age".publicKeys = [ main my ];
  "nextcloud/maria_root_pass.age".publicKeys = [ main my ];
  "nextcloud/maria_pass.age".publicKeys = [ main my ];
  "nextcloud/admin_pass.age".publicKeys = [ main my ];
}
