{ pkgs, home, lib, ... }: {
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
      saveundo = true;
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

  exported-services = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "Services to export to prometheus";
  };

  systemd.user.services.exporter = {
    enable = lib.length exported-services > 0;
     Unit = {
      Description = "Service for Systemd Exporter";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = ''
        ${pkgs.prometheus-systemd-exporter}/bin/systemd_exporter \
          --web.listen-address ${config.address.private.systemd-exporter."${name}"} --systemd.collector.user \
          --systemd.collector.unit-include=${lib.concatStringsSep "|" exported-services}
      '';
    };
  };
}
