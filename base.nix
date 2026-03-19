{
  config,
  pkgs,
  ...
}:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  boot.tmp.cleanOnBoot = true;

  zramSwap.enable = true;
  services = {
    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
      };
    };
    logind.settings.Login.KillUserProcesses = false;
    fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
      ignoreIP = [
        "10.0.0.0/24"
      ];
      bantime-increment.enable = true;
      bantime-increment.rndtime = "20m";
      bantime-increment.maxtime = "2d";
    };
  };

  system.stateVersion = "24.11";
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "8192";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "524288";
    }
  ];
  systemd.settings.Manager = {
    DefaultLimitNOFILE = "8192:524288";
  };

  time.timeZone = "Europe/Berlin";
  networking.domain = "h3rmt.dev";
  networking.useDHCP = false;

  security.protectKernelImage = true;
  security.sudo.enable = false;

  users.users.root = {
    openssh.authorizedKeys.keys = [ config.custom.my-public-key ];
    hashedPasswordFile = config.age.secrets.root-pass.path;
    isSystemUser = true;
  };

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    historyLimit = 40000;
    shortcut = "Space";
    extraConfigBeforePlugins = ''
      set -g @dracula-plugins " "
      set -g @dracula-show-powerline true
      set -g @dracula-show-flags true
      set -g @dracula-refresh-rate 5
      set -g @dracula-show-left-icon hostname
    '';
    plugins = with pkgs.tmuxPlugins; [
      cpu
      dracula
    ];
    terminal = "xterm-256color";
    extraConfig = ''
      set -s escape-time 10         # faster command sequences
      set -g display-panes-time 800 # slightly longer pane indicators display time
      set -g display-time 1000      # slightly longer status messages display time
      set -g status-interval 10     # redraw status line every 10 seconds
      set -g repeat-time 50         # dont allow fast key repetition
      set -g renumber-windows on
      set -g mouse on

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

      bind r source-file /etc/tmux.conf \; display "Reloaded!"
    '';
  };

  environment.systemPackages = with pkgs; [
    git
    micro
    btop
    htop
    tmux
    fail2ban
    curl
    wget
    unzip
    tree
    ripgrep
    nix-output-monitor
    dig
    jq
    openssl
    nmap
    ncdu
    k9s
    nfs-utils
    iptables
    wireguard-tools
  ];
}
