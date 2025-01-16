{ lib, config, ... }: {
  create-files = home: files: (lib.mapAttrs (name: { text, noLink ? false, onChange ? "", executable ? false }: {
    inherit text;
    inherit executable;
    target = if noLink then ".links/${name}" else "${name}";
    onChange =
      if noLink then ''
        rm -f ${home}/${name}
        install -D ${home}/.links/${name} ${home}/${name}
        chmod 555 ${home}/${name}
        
        ${onChange}
      ''
      else onChange;
  })) files;

  create-folders = llib: folders: llib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${toString folders}
  '';

  # generateUserDataDirs = map (userName: "/home/${userName}/${config.data-dir}") builtins.attrNames config.users.users;
}
