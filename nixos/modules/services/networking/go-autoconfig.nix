{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.go-autoconfig;
  configFile = pkgs.writeText "go-autoconfig.conf" ''
    service_addr: ":${toString cfg.port}"

    domain: ${cfg.domain}

    imap:
      server: ${cfg.imap.server}
      port: ${toString cfg.imap.port}

    smtp:
      server: ${cfg.smtp.server}
      port: ${toString cfg.smtp.port}
  '';

in {
  options = {
    services.go-autoconfig = {

      enable = mkEnableOption "IMAP/SMTP autodiscover feature for mail clients";

      port = mkOption {
        type = types.port;
        default = 1323;
        description = mdDoc "Port to listen on (use 0 for random port).";
      };

      domain = mkOption {
        type = types.str;
        default = "localhost";
        description = mdDoc "Domainname used for autoconfig server.";
        example = "autoconfig.example.org";
      };

      imap = {

        server = mkOption {
          type = types.str;
          default = "localhost";
          description = mdDoc "Domainname used for autoconfig server.";
          example = "imap.example.org";
        };

        port = mkOption {
          type = types.port;
          default = 993;
          description = mdDoc "IMAP port your mail server is listening on.";
        };

      };

      smtp = {

        server = mkOption {
          type = types.str;
          default = "localhost";
          description = mdDoc "Domainname used for autoconfig server.";
          example = "smtp.example.org";
        };

        port = mkOption {
          type = types.port;
          default = 587;
          description = mdDoc "SMTP port your mail server is listening on.";
        };

      };

    };
  };

  config = mkIf cfg.enable {

    systemd = {
      services.go-autoconfig = {
        wantedBy = [ "multi-user.target" ];
        description = "IMAP/SMTP autodiscover server";
        after = [ "network.target" ];
        restartTriggers = [ configFile ];
        serviceConfig = {
          ExecStart = "${pkgs.go-autoconfig}/bin/go-autoconfig -config ${configFile}";
          KillSignal = "SIGINT";
          Restart = "on-failure";
        };
      };
    };

  };

  meta.maintainers = with lib.maintainers; [ onny ];

}
