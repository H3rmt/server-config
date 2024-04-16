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
    initExtra = ''source ~/${p10k};'';
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
  };
}
