{ lib, config, clib, ... }: {
  imports = [
    ../baseuser.nix
  ];
  home.stateVersion = config.nixVersion;

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/${config.backup-dir}"
    "${config.data-prefix}/${config.remote-backup-dir}"
  ];
}
