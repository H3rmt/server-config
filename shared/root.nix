{ lib, config, home, pkgs, inputs, ... }: 
let
  clib = import ./funcs.nix { inherit lib; inherit config; };
  age = config.age;
  hostName = config.networking.hostName;
in
{
  home-manager.users."${config.backup-user-prefix}-${hostName}" = { home, lib, config, ... }: {
    imports = [
      ./usr.nix
    ];
    home.stateVersion = config.nixVersion;

    home.activation.script = clib.create-folders lib [
      "${config.data-prefix}/backups/"
    ];

    # Generate a new SSH key (only if missing => must be updated in config after that)
    home.activation.generateSSHKey = ''
      test -f ${config.home.homeDirectory}/.ssh/id_ed25519 || run ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f ${config.home.homeDirectory}/.ssh/id_ed25519 -N ""
    '';

    exported-services = [ "borgmatic.timer" "borgmatic.service" ];

    services.borgmatic = {
      enable = true;
      frequency = "*:0/30"; # Every 30 minutes
    };

    programs.borgmatic = {
      enable = true;
      backups = {
        user-data = {
          location = {
            patterns = [
              "/home/*/${config.data-dir}"
            ];
            repositories = [
              {
                "path" = "ssh://${config.backup-user-prefix}-main-nix-1@${config.main-nix-1-private-ip}:${toString config.ports.exposed.ssh}/home/${config.backup-user-prefix}-main-nix-1/backups/${hostName}";
                "label" = "remote-1";
              }
              {
                "path" = "ssh://${config.backup-user-prefix}-main-nix-2@${config.main-nix-2-private-ip}:${toString config.ports.exposed.ssh}/home/${config.backup-user-prefix}-main-nix-2/backups/${hostName}";
                "label" = "remote-2";
              }
            ];
          };
          retention = {
            keepDaily = 7;
            keepWeekly = 4;
            keepMonthly = 6;
          };
          storage = {
            encryptionPasscommand = "cat '${age.secrets.borg_pass.path}'";
          };
          output.extraConfig = {
            ssh_command = "ssh -i /etc/ssh/ssh_host_ed25519_key";
            compression = "zstd,15";
          };
        };
      };
    };
  };

  home-manager.users.root = {
    imports = [
      ./usr.nix
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

          bind r source-file ${config.users.users.root.home}/.config/tmux/tmux.conf \; display "Reloaded!"
        '';
      };
    };
  };
}
