{ lib, config, home, pkgs, inputs, ... }: {
  home-manager.users.root = {
    imports = [
      ../../usr.nix
    ];
    home.stateVersion = config.nixVersion;
    home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

    programs.git = {
      enable = true;
      userName = "Enrico Stemmer";
      userEmail = "stemmer.enrico@gmail.com";
    };

    programs.tmux = {
      enable = true;
      baseIndex = 1;
      clock24 = true;
      historyLimit = 10000;
      mouse = true;
      prefix = "C-Space";
      plugins =
        let
          tmux-dracula = pkgs.tmuxPlugins.mkTmuxPlugin
            {
              pluginName = "dracula";
              version = "unstable-2024-05-05";
              src = pkgs.fetchFromGitHub {
                owner = "dracula";
                repo = "tmux";
                rev = "master";
                sha256 = "sha256-rP4kiSSz/JN47ogC5S+2h5ACS0tgjvRxCclBc5WQZGk=";
              };
            };
        in
        [
          pkgs.tmuxPlugins.cpu
          pkgs.tmuxPlugins.sidebar
          {
            plugin = tmux-dracula;
            extraConfig = ''
              set -g @dracula-plugins "cpu-usage ram-usage network ssh-session"
              set -g @dracula-show-powerline true
              set -g @dracula-show-flags true
              set -g @dracula-refresh-rate 3
              set -g @dracula-show-left-icon hostname
            '';
          }
        ];
      terminal = "screen-256color";
      extraConfig = ''
        unbind '"'
        unbind %

        bind | split-window -hc "#{pane_current_path}"
        bind - split-window -vc "#{pane_current_path}"

        bind -r "<" swap-window -d -t -1
        bind -r ">" swap-window -d -t +1

        set -g set-clipboard on

        bind c new-window -c "#{pane_current_path}"

        set -g @yank_action 'copy-pipe-no-clear'
        set -s exit-empty off

        bind C-p previous-window
        bind C-n next-window

        bind r source-file ${config.users.users.root.home}/.config/tmux/tmux.conf \; display "Reloaded!"
      '';
    };
  };
}
