let
  main = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAz2IRRlU5CN8TRnHnHD98R5CWSGHQBg9hxqeYARdoK";
  my = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t";
in
{
  "borg_pass.age".publicKeys = [ main my ];
  "root_pass.age".publicKeys = [ main my ];
  "reverseproxy/hetzner_token.age".publicKeys = [ main my ];
}
