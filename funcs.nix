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
        };
      }));
    };
  };

  config = {
    home.file = lib.mapAttrs
      (name: cfg: {
        text = cfg.text;
        onChange = ''${toString cfg.noLink}'';
      })
      config.create-files;
  };
}
