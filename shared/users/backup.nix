{ lib, config, clib, mainConfig, ... }: {
  imports = [
    ../baseuser.nix
  ];
  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/${mainConfig.backup-dir}"
    "${config.data-prefix}/${mainConfig.remote-backup-dir}"
  ];
}
