{ lib, config, home, pkgs, clib, mainConfig, inputs, ... }:
let
  SUNNY_PASSWORD = ''$(cat "${mainConfig.age.secrets.sunny_password.path}")'';
in
{
  imports = [
    ../../shared/baseuser.nix
  ];

  exported-services = [ "send.service" ];

  systemd.user = {
    services = {
      send = {
        Unit = {
          Description = "Send images to raspi";
        };
        Service = {
          ExecStart = pkgs.writeShellApplication
            {
              name = "send";
              runtimeInputs = [ pkgs.openssh ];
              text = ''
                
              '';
            } + /bin/send;
        };
        Install = { WantedBy = [ "default.target" ]; };
      };
    };
  };


  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=puppeteer-sma -d --pod=${config.pod-name} \
            --restart on-failure:10 \
            -u $UID:$GID \
            -e SUNNY_USERNAME="stemmer.enrico@gmail.com" \
            -e SUNNY_PASSWORD=${SUNNY_PASSWORD} \
            -e SCREENSHOT_DELAY=6000 \
            -v ${config.data-prefix}:/app/images:U \
            ghcr.io/h3rmt/puppeteer-sma:${mainConfig.image-versions."ghcr.io/h3rmt/puppeteer-sma"}

        ${config.exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 puppeteer-sma
        podman rm puppeteer-sma
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
      '';
    };
  };
}
