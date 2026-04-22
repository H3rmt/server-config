## Install: 
```
# adjust networking and copy generated hardware config from /etc/nixos

# check nix channel
nix-channel --list
nix-channel --remove nixos
nix-channel --add https://nixos.org/channels/nixos-unstable nixos
nix-channel --update

nix-shell -p git nix-output-monitor micro htop tmux

mv /etc/nixos /etc/nixos-old
git clone git@github.com:H3rmt/server-config.git /etc/nixos

cat /etc/ssh/ssh_host_ed25519_key.pub
# insert into host.nix
# age.rekey.hostPubkey = "..."

# update boot.* in host.nix

# update ips, macs, etc in net.nix

# update secrets (nix develop --command $SHELL)
agenix rekey -a

nixos-rebuild switch --flake '.#' |& nom
```

## Generate Wireguard Key
```bash
wg genkey > privatekey
wg pubkey < privatekey > publickey
```

## Initial Setup:
agenix-rekey:
1. generate a private + public key `age-keygen -o master.agekey` 
2. encrypt private key with age: `age -p -o privkey.age master.agekey` 
3. paste public key into masterIdentities

## ZFS

```
zfs create -o keyformat=passphrase -o keylocation=file:///run/agenix/zfs-key -o encryption=aes-256-gcm tank/...
zfs set mountpoint=/mnt/tank-... tank/...
zfs list
```