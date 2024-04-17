{ lib, config, ... }: {
  # addOnChange = { name, text }: {
  #   "__${name}" = {
  #     onChange = ''
  #       rm -f ${config.home.homeDirectory}/${name}
  #       ln ${config.home.homeDirectory}/_${name} ${config.home.homeDirectory}/${name}
  #       chmod 500 ${config.home.homeDirectory}/${name}
  #     '';
  #     text = "${text}";
  #     target = "_${name}";
  #   };
  # };

  options = {
    create-files = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {
          text = lib.mkOption {
            type = lib.types.str;
          };
          noLink = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          onChange = lib.mkOption {
            type = lib.types.lines;
            default = "";
          };
          executable = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
        };
      }));
    };
  };

  config = {
    home.file = lib.mapAttrs
      (name: cfg: {
        text = cfg.text;
        target = if cfg.noLink then ".links/${name}" else "${name}";
        executable = cfg.executable;
        # recursive = true; 
        onChange =
          if cfg.noLink then ''
            rm -f ${config.home.homeDirectory}/${name}
            install -D ${config.home.homeDirectory}/.links/${name} ${config.home.homeDirectory}/${name}
            chmod 500 ${config.home.homeDirectory}/${name}
          ''
          else cfg.onChange;
      })
      config.create-files;
  };
}
