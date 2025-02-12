let
  main = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGc6KRvmMWOHx8gHICOnXdDkqA4q08e5xTKP3BJt5rGo";
  my = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t";
in
{
  "borg/main-nix-1.age".publicKeys = [ main my ];
  "borg/main-nix-2.age".publicKeys = [ main my ];
  "borg/raspi-1.age".publicKeys = [ main my ];
  "root_pass.age".publicKeys = [ main my ];
  "wireguard_private.age".publicKeys = [ main my ];
}
