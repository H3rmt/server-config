### Clone: 
```
mv /etc/nixos /etc/nixos-old

nix-shell -p git nix-output-monitor micro

git clone https://github.com/H3rmt/server-config /etc/nixos

# adjust networking and copy generated hardware config
# set hostname

nixos-rebuild switch --flake '.#' |& nom
```