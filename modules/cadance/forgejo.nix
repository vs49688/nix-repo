{ config, pkgs, lib, ... }:
let
  cfg = config.cadance.forgejo;
in
{
  options.cadance.forgejo = with lib; {
    enable = mkEnableOption "Enable CADANCE Forgejo";

    appName = mkOption {
      type = types.str;
      example = "My Forgejo";
    };

    hostName = mkOption {
      type = types.str;
      example = "git.example.com";
    };

    noreplyEmail = mkOption {
      type = types.str;
      example = "noreply@example.com";
    };

    smtpAddress = mkOption {
      type = types.str;
      example = "smtp.example.com";
    };

    smtpUsername = mkOption {
      type = types.str;
      example = "noreply@example.com";
    };

    smtpPasswordFile = mkOption {
      type = types.str;
    };

    runnerTokenFile = mkOption {
      type = types.str;
    };

    localNetworks = mkOption {
      type = types.listOf types.str;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    ##
    # Note that we use git@ instead for forgjo@ for SSH.
    ##
    users.groups.git.gid = 1001;
    users.users.git = {
      isNormalUser = true;
      group        = "git";
      uid          = 1001;
      home         = "/var/lib/forgejo";
    };

    services.forgejo = {
      enable              = true;

      user                = "git";
      group               = "git";

      database.type       = "postgres";
      database.user       = "git";
      database.name       = "forgejo";
      database.socket     = "/run/postgresql";
      database.createDatabase = false;

      lfs.enable          = true;

      package = pkgs.forgejo; # Not LTS

      secrets.mailer.PASSWD = cfg.smtpPasswordFile;

      settings = {
        DEFAULT.APP_NAME = cfg.appName;

        log = {
          LEVEL = "Info";
        };

        database = {
          LOG_SQL = false;
        };

        indexer = {
          ISSUE_INDEXER_TYPE = "db";
        };

        session = {
          PROVIDER          = "db";
          COOKIE_SECURE     = true;
          SESSION_LIFE_TIME = 1209600; # 2 weeks
          DOMAIN            = cfg.hostName;
          SAME_SITE         = "lax"; # Breaks OAuth2 external login if strict
        };

        server = {
          ROOT_URL    = "https://${cfg.hostName}/";
          DOMAIN      = cfg.hostName;
          PROTOCOL    = "http+unix";
          DISABLE_SSH = false;
          SSH_PORT    = 22;
          SSH_DOMAIN  = "%(DOMAIN)s";

          OFFLINE_MODE       = true;
          DISABLE_ROUTER_LOG = true;
          LANDING_PAGE       = "explore";
        };

        security = {
          IMPORT_LOCAL_PATHS  = false;
          LOGIN_REMEMBER_DAYS = 14;
          REVERSE_PROXY_TRUSTED_PROXIES = "127.0.0.0/8,::1/128";
        };

        cors = {
          ENABLED         = true;
          SCHEME          = "https";
          ALLOW_DOMAIN    = cfg.hostName;
          ALLOW_SUBDOMAIN = false;
        };

        ##
        # Can't use system sendmail:
        # Work around https://github.com/NixOS/nixpkgs/issues/42117
        ##
        mailer = {
          ENABLED = true;
          PROTOCOL       = "smtps";
          SMTP_ADDR      = cfg.smtpAddress;
          SMTP_PORT      = 465;
          HELO_HOSTNAME  = cfg.hostName;
          USER           = cfg.smtpUsername;

          SEND_AS_PLAIN_TEXT = true;
          FROM               = "%(APP_NAME)s <${cfg.noreplyEmail}>";
          SUBJECT_PREFIX     = "[%(APP_NAME)s]";
        };

        service = {
          REGISTER_EMAIL_CONFIRM         = false;
          ENABLE_NOTIFY_MAIL             = true;
          ENABLE_CAPTCHA                 = false;
          REQUIRE_SIGNIN_VIEW            = false;
          DEFAULT_KEEP_EMAIL_PRIVATE     = true;
          DISABLE_REGISTRATION           = true;
        };

        picture = {
          DISABLE_GRAVATAR               = true;
          ENABLE_FEDERATED_AVATAR        = false;
        };

        openid = {
          ENABLE_OPENID_SIGNIN           = false;
          ENABLE_OPENID_SIGNUP           = false;
        };

        oauth2_client = {
          USERNAME = "userid";
          ACCOUNT_LINKING = "auto";
        };

        attachment = {
          ENABLED                        = true;
          PATH                           = "${config.services.forgejo.stateDir}/data/attachments";
          ALLOWED_TYPES                  = "*/*";
          MAX_SIZE                       = 500;
          MAX_FILES                      = 5;
        };

        ui = {
          DEFAULT_THEME = "forgejo-dark";
        };

        "cron.repo_health_check" = {
          SCHEDULE                       = "@every 24h";
          TIMEOUT                        = "300s";
        };

        other = {
          SHOW_FOOTER_BRANDING           = false;
          SHOW_FOOTER_VERSION            = false;
          SHOW_FOOTER_TEMPLATE_LOAD_TIME = false;
        };

        repository = {
          DEFAULT_BRANCH          = "master";
          ENABLE_PUSH_CREATE_USER = true;
          ENABLE_PUSH_CREATE_ORG  = true;
        };

        "git.timeout" = {
          MIGRATE = 3600; # 1 hour
        };

        metrics = {
          ENABLED = true;
          ENABLE_ISSUE_BY_LABEL = true;
          ENABLE_ISSUE_BY_REPOSITORY_LABEL = true;
        };

        actions = {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = "https://${cfg.hostName}";
        };
      };
    };
    systemd.services.forgejo.requires = lib.mkForce [];
    users.groups.git.members = [ config.services.caddy.group ];

    services.gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances.CADANCE = {
        enable = true;
        name = config.networking.hostName;
        url = config.services.forgejo.settings.server.ROOT_URL;
        tokenFile = cfg.runnerTokenFile;
        labels = [
          "debian-latest:docker://node:25-bullseye"
          "ubuntu-latest:docker://node:25-bullseye"
          "nixos:docker://${cfg.hostName}/oci/forgejo-ci-nix:latest"
        ];
        settings = {
          runner.capacity = 5;
          runner.insecure = false;
        };
      };
    };

    systemd.services.gitea-runner-CADANCE.path = [
      pkgs.gitFull
    ];

    services.caddy.virtualHosts."${cfg.hostName}".extraConfig = ''
      @local remote_ip 127.0.0.1 ::1 fe80::/10 ${lib.concatStringsSep " " cfg.localNetworks}

      @external not { remote_ip 127.0.0.1 ::1 }

      handle /metrics {
        log_skip

        handle @external {
          respond 403
        }

        reverse_proxy unix//run/forgejo/forgejo.sock {
          header_up X-Real-Ip {remote_host}
        }
      }

      handle @local {
        reverse_proxy unix//run/forgejo/forgejo.sock {
          header_up X-Real-Ip {remote_host}
        }
      }

      log_skip /api/actions/runner.v1.RunnerService/FetchTask
      log_skip /api/actions/runner.v1.RunnerService/UpdateLog
      log_skip /api/actions/runner.v1.RunnerService/UpdateTask

      reverse_proxy unix//run/anubis/anubis-forgejo/anubis.sock {
        header_up X-Real-Ip {remote_host}
      }
    '';

    services.anubis.instances.forgejo = {
      enable = true;
      user = "caddy";
      group = "caddy";
      settings.TARGET = "unix:///run/forgejo/forgejo.sock";
      settings.COOKIE_DYNAMIC_DOMAIN = true;
      settings.difficulty = 5;
    };
  };
}