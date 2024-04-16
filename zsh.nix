{ pkgs, home, ... }:
let
  p10k = ".p10k.zsh";
in
{
  home.file."${p10k}" = {
    source = ./p10k.zsh;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    autocd = true;
    history.size = 10000;
    history.share = false;
    initExtra = ''
      bindkey "^[[1;5C" forward-word;
      bindkey "^[[1;5D" backward-word;
      source ~/${p10k};
      eval "$(zoxide init zsh)";
      alias cd=z;
      alias ls=eza;
      alias grep=rg;
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
