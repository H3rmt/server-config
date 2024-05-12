{ pkgs, home, ... }:
let
  p10k = ".p10k.zsh";
in
{
  home.file."${p10k}" = {
    source = ./p10k.zsh;
  };

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
      
      source ~/${p10k};
      eval "$(zoxide init zsh)";
      
      alias cd="z";
      alias ls="eza -a";
      alias ll="eza -lahg --icons --git";
      alias grep="rg";
    '';
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
  };
}
