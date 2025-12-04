## Install: 
```
# adjust networking and copy generated hardware config from /etc/nixos

# check nix channel
```
nix-channel --list
nix-channel --remove nixos
nix-channel --add https://nixos.org/channels/nixos-unstable nixos
nix-channel --update

mv /etc/nixos /etc/nixos-old

nix-shell -p git nix-output-monitor micro
git clone https://github.com/H3rmt/server-config /etc/nixos
nixos-rebuild switch --flake '.#' |& nom
```