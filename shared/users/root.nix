{ age, clib }: { lib, config, home, pkgs, inputs, ... }: {
  imports = [
    ../usr.nix
  ];
  home.stateVersion = config.nixVersion;
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

  programs = {
    git = {
      enable = true;
      userName = "Enrico Stemmer";
      userEmail = "${config.email}";
    };

    tmux = {
      enable = true;
      baseIndex = 1;
      clock24 = true;
      historyLimit = 40000;
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
      terminal = "xterm-256color";
      extraConfig = ''
        set -s escape-time 10         # faster command sequences
        set -g display-panes-time 800 # slightly longer pane indicators display time
        set -g display-time 1000      # slightly longer status messages display time
        set -g status-interval 10     # redraw status line every 10 seconds
        set -g repeat-time 50         # dont allow fast key repetition
        set -g renumber-windows on

        unbind '"'
        unbind %

        bind | split-window -hc "#{pane_current_path}"
        bind - split-window -vc "#{pane_current_path}"

        bind -r "<" swap-window -d -t -1
        bind -r ">" swap-window -d -t +1

        set -g set-clipboard on

        bind c new-window -c "#{pane_current_path}"

        set -g @yank_action 'copy-pipe-no-clear'
        set -g exit-empty off

        bind C-p previous-window
        bind C-n next-window

        bind r source-file ${config.home.homeDirectory}/.config/tmux/tmux.conf \; display "Reloaded!"
      '';
    };
  };
}
