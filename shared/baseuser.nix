{ pkgs, lib, config, mainConfig, clib, ... }: {
  options = {
    exported-services = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Services to export to prometheus";
      default = [ ];
    };
    data-prefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for data folders";
    };
    pod-name = lib.mkOption {
      type = lib.types.str;
      description = "Name of pod for container";
    };
    exporter = lib.mkOption {
      type = lib.types.submodule {
        options = {
          run = lib.mkOption {
            type = lib.types.str;
          };
          stop = lib.mkOption {
            type = lib.types.str;
          };
          port = lib.mkOption {
            type = lib.types.str;
          };
        };
      };
    };
  };

  config = rec {
    data-prefix = "${config.home.homeDirectory}/${mainConfig.data-dir}";
    pod-name = "${config.home.username}_pod";
    exporter = {
      run = ''
        # exporter-config-empty:/.config:U is a workaround for podman-exporter needing $HOME/.config idk why
        podman run --name=podman-exporter-${config.home.username} -d --pod=${config.pod-name} \
            -e CONTAINER_HOST=unix:///podman.sock \
            -v $XDG_RUNTIME_DIR/podman/podman.sock:/podman.sock:U \
            -v exporter-config-empty:/.config:U \
            --restart on-failure:20 \
            -u $UID:$GID \
            quay.io/navidys/prometheus-podman-exporter:${mainConfig.podman-exporter-version} \
            --collector.pod --web.disable-exporter-metrics
      '';

      stop = ''
        podman stop -t 10 podman-exporter-${config.home.username}
        podman rm podman-exporter-${config.home.username}
      '';

      port = ''${mainConfig.address.private.podman-exporter.${config.home.username}}:9882'';
    };
    home.stateVersion = mainConfig.nixVersion;
    home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

    home.activation.dirs = clib.create-folders lib [
      "${data-prefix}"
    ];

    xdg.configFile."micro/bindings.json" = {
      text = builtins.toJSON {
        "Ctrl-j" = "command-edit:jump ";
        "Ctrl-l" = "command-edit:goto ";
      };
    };

    programs.micro = {
      enable = true;
      settings = {
        clipboard = "terminal";
        hltaberrors = true;
        mkparents = true;
        reload = "auto";
        relativeruler = true;
        savecursor = true;
        scrollbar = true;
        tabstospaces = true;
      };
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      autosuggestion.enable = true;
      autocd = true;
      history = {
        size = 10000;
        share = false;
      };
      initExtra = ''
        export EDITOR=micro

        bindkey "^[[1;5C" forward-word;
        bindkey "^[[1;5D" backward-word;


        autoload -U promptinit; promptinit
        zstyle ':prompt:pure:host' color cyan
        zstyle ':prompt:pure:user:root' color red
        zstyle ':prompt:pure' git false
        # force display of user@host
        export PROMPT_PURE_SSH_CONNECTION="1"
        export PURE_GIT_PULL=0
        prompt pure

        eval "$(zoxide init zsh)";
        
        alias cd="z";
        alias ls="eza -a";
        alias ll="eza -lahg --icons --git";
        alias grep="rg";
      '';
      plugins = [ ];
    };

    systemd.user = {
      services.exporter =
        if (config.exported-services != [ ]) then {
          Unit = {
            Description = "Service for Systemd Exporter: ${builtins.toJSON config.exported-services}";
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
          Service = {
            ExecStart = ''
              ${pkgs.prometheus-systemd-exporter}/bin/systemd_exporter \
                --web.listen-address ${mainConfig.address.private.systemd-exporter.${config.home.username}} --systemd.collector.user --systemd.collector.unit-include=${lib.concatStringsSep "|" config.exported-services}
            '';
          };
        } else { };
    };
  };
}
