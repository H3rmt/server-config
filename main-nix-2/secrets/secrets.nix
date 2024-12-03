let
  main = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAz2IRRlU5CN8TRnHnHD98R5CWSGHQBg9hxqeYARdoK";
  my = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t";
in
{
  "borg/main-nix-1.age".publicKeys = [ main my ];
  "borg/main-nix-2.age".publicKeys = [ main my ];
  "borg/raspi-1.age".publicKeys = [ main my ];
  "root_pass.age".publicKeys = [ main my ];
  "wireguard_private.age".publicKeys = [ main my ];
  "reverseproxy/hetzner_token.age".publicKeys = [ main my ];
  "authentik/pg_pass.age".publicKeys = [ main my ];
  "authentik/authentik_key.age".publicKeys = [ main my ];
  "grafana/client_secret.age".publicKeys = [ main my ];
  "grafana/client_key.age".publicKeys = [ main my ];
  "wakapi/salt.age".publicKeys = [ main my ];
  "grafana/wakapi_metrics_key.age".publicKeys = [ main my ];
}
