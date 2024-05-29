{ pkgs, home, lib, config, ... }: {
  imports = [
    ./vars.nix
  ];
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

  config = {
    data-prefix = "${config.home.homeDirectory}/${config.data-dir}";
    pod-name = "${config.home.username}_pod";
    exporter = {
      run = ''
        podman run --name=podman-exporter-${config.home.username} -d --pod=${config.pod-name} \
            -e CONTAINER_HOST=unix:///run/podman/podman.sock \
            -v $XDG_RUNTIME_DIR/podman/podman.sock:/run/podman/podman.sock \
            --restart on-failure:10 \
            quay.io/navidys/prometheus-podman-exporter:${config.podman-exporter-version} \
            --collector.enable-all
      '';

      stop = ''
        podman stop -t 10 podman-exporter-${config.home.username}
        podman rm podman-exporter-${config.home.username}
      '';

      port = ''${config.address.private.podman-exporter.${config.home.username}}:9882'';
    };
    home.stateVersion = config.nixVersion;
    home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

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
        # force display of user@host
        export PROMPT_PURE_SSH_CONNECTION="1"
        prompt pure

        eval "$(zoxide init zsh)";
        
        alias cd="z";
        alias ls="eza -a";
        alias ll="eza -lahg --icons --git";
        alias grep="rg";
      '';
      plugins = [ ];
    };

    systemd.user.services.exporter =
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
              --web.listen-address ${config.address.private.systemd-exporter.${config.home.username}} --systemd.collector.user --systemd.collector.unit-include=${lib.concatStringsSep "|" config.exported-services}
          '';
        };
      } else { };
  };
}
