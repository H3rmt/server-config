let
  main = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3IVwWPgIK0goGqR7IoN9OE/TuAKHrXLZPOkByWdOII";
in
{
  "filesharing/admin_pass.age".publicKeys = [ main ];
  "filesharing/admin_email.age".publicKeys = [ main ];
  "filesharing/user_pass.age".publicKeys = [ main ];
  "root_pass.age".publicKeys = [ main ];
}
