{ lib, config, clib, mainConfig, ... }: {
  imports = [
    ../baseuser.nix
  ];
  home.activation.script = clib.create-folders lib [
    "${mainConfig.backup-dir}"
    "${mainConfig.remote-backup-dir}"
  ];
}
