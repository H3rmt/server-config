{ inputs, lib, config, pkgs, ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  boot.tmp.cleanOnBoot = true;

  zramSwap.enable = true;
  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
      };
    };
    logind.killUserProcesses = false;
    fail2ban = {
      enable = true;
      maxretry = 3;
      bantime = "1h";
      ignoreIP = [
        "10.0.0.0/8"
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
    options = "--delete-older-than 7d";
  };

  security.pam.loginLimits = [{
    domain = "*";
    type = "soft";
    item = "nofile";
    value = "8192";
  }];

  time.timeZone = "Europe/Berlin";
  networking.domain = "h3rmt.zip";
  networking.useDHCP = false;

  environment.memoryAllocator.provider = "scudo";
  security.protectKernelImage = true;
  security.sudo.enable = false;

  users.users.root = {
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t" ];
    isSystemUser = true;
    hashedPassword = "$6$/P2qgCx3wxHIcZzN$nPBYexKPD.4eGGO0eBZSnyin6e1uW4VYvsh0nrfunaJ0/bq6O9IEGvN5EZHQ/b5Q7bImGm1s/PRdxT2cpharT1";
  };

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    historyLimit = 40000;
    shortcut = "Space";
    plugins = with pkgs.tmuxPlugins; [ cpu dracula ];
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

      bind r source-file /root/.config/tmux/tmux.conf \; display "Reloaded!"

      set -g @dracula-plugins " "
      set -g @dracula-show-powerline true
      set -g @dracula-show-flags true
      set -g @dracula-refresh-rate 5
      set -g @dracula-show-left-icon hostname
    '';
  };

  environment.systemPackages = [
    pkgs.git
    pkgs.micro
    pkgs.btop
    pkgs.htop
    pkgs.tmux
    pkgs.fail2ban
    pkgs.curl
    pkgs.wget
    pkgs.unzip
    pkgs.tree
    pkgs.ripgrep
    pkgs.nix-output-monitor
    pkgs.dig
    pkgs.jq
    pkgs.openssl
    pkgs.nmap
    inputs.agenix.packages.${pkgs.system}.default
  ];
}
