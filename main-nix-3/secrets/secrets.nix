let
  main = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3IVwWPgIK0goGqR7IoN9OE/TuAKHrXLZPOkByWdOII";
  my = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t";
in
{
  "root_pass.age".publicKeys = [ main my ];
}
