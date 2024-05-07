let
  main = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKIpoY7xkKbUMJ1/Fg1jPu1jwQzfXgjvybcsXnbI0eM";
in
{
  "filesharing/admin_pass.age".publicKeys = [ main ];
  "filesharing/admin_email.age".publicKeys = [ main ];
  "filesharing/user_pass.age".publicKeys = [ main ];
}
