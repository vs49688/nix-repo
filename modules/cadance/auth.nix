{ config, lib, pkgs, ... }: let
  cfg = config.cadance.auth;

  totpIssuer = cfg.authelia.host;
  webauthnDisplayName = cfg.authelia.host;

  autheliaServiceName = "authelia-${cfg.authelia.domain}";
in {
  options.cadance.auth = with lib; {
    enable = mkEnableOption "Enable CADANCE Auth";

    localNetworks = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    lldap = mkOption {
      type = types.submodule {
        options = {
          host = mkOption {
            type = types.str;
            example = "id.example.com";
          };

          baseDN = mkOption {
            type = types.str;
            description = "LLDAP Base DN";
            example = "dc=example,dc=com";
          };

          adminUserEmail = mkOption {
            type = types.str;
          };

          adminUserDN = mkOption {
            type = types.str;
          };

          jwtSecretFile = mkOption {
            type = types.str;
            description = "Used in LLDAP_JWT_SECRET_FILE. Mounted as a systemd secret";
          };

          userPassFile = mkOption {
            type = types.str;
            description = "Used in LLDAP_LDAP_USER_PASS_FILE. Mounted as a systemd secret";
          };

          keyFile = mkOption {
            type = types.str;
            description = "Used in LLDAP_KEY_FILE. Mounted as a systemd secret";
          };
        };
      };
    };

    authelia = mkOption {
      type = types.submodule {
        options = {
          host = mkOption {
            type = types.str;
            description = "Authelia Hostname";
            example = "auth.example.com";
          };

          domain = mkOption {
            type = types.str;
            example = "example.com";
          };

          ldapPasswordFile = mkOption {
            type = types.str;
            description = "Used in AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE. Mounted as a systemd secret";
          };

          jwtSecretFile = mkOption {
            type = types.str;
            description = "Used in AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE. Mounted as a systemd secret";
          };

          storageEncryptionKeyFile = mkOption {
            type = types.str;
            description = "Used in AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE. Mounted as a systemd secret";
          };

          sessionSecretFile = mkOption {
            type = types.str;
            description = "Used in AUTHELIA_SESSION_SECRET_FILE. Mounted as a systemd secret";
          };

          oidcHmacSecretFile = mkOption {
            type = types.str;
            description = "Used in AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE. Mounted as a systemd secret";
          };

          smtpAddress = mkOption {
            type = types.str;
            example = "submissions://smtp.example.com:465";
          };

          smtpUsername = mkOption {
            type = types.str;
            example = "noreply@example.com";
          };

          smtpSender = mkOption {
            type = types.str;
            example = "Authelia <noreply@cadance.example.com>";
          };

          smtpPasswordFile = mkOption {
            type = types.str;
            description = "Used in AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE. Mounted as a systemd secret";
          };

          jwksKey = mkOption {
            type = types.str;
          };

          clientsYml = mkOption {
            type = types.str;
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {

    services.postgresql.enable = true;

    services.postgresql.ensureDatabases = [
      "lldap"
      "authelia"
    ];

    services.postgresql.ensureUsers = [
      { name = "lldap"; ensureDBOwnership = true; }
      { name = "authelia"; ensureDBOwnership = true; }
    ];

    users.groups.authelia = {
      members = [ "caddy" ];
    };
    users.users.authelia.group = "authelia";
    users.users.authelia.isSystemUser = true;

    ##
    # LLDAP
    ##
    services.lldap = {
      enable = true;
      settings = {
        http_host = "127.0.0.1";
        http_port = 17170;

        ldap_host = "127.0.0.1";
        ldap_base_dn = cfg.lldap.baseDN;
        ldap_user_email = cfg.lldap.adminUserEmail;
        ldap_user_dn = cfg.lldap.adminUserDN;

        database_url = "postgres:///lldap?user=lldap&host=/run/postgresql";
      };

      # %d = Credentials directory
      # https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html
      environment.LLDAP_JWT_SECRET_FILE = "%d/jwt_secret";
      environment.LLDAP_LDAP_USER_PASS_FILE = "%d/user_pass";
      environment.LLDAP_KEY_FILE = "%d/key_file";
    };

    systemd.services.lldap.serviceConfig.LoadCredential = [
      "jwt_secret:${cfg.lldap.jwtSecretFile}"
      "user_pass:${cfg.lldap.userPassFile}"
      "key_file:${cfg.lldap.keyFile}"
    ];
    systemd.services.lldap.requires = [ "postgresql.target" ];

    ##
    # Authelia
    ##
    services.redis.servers."authelia" = {
      enable = true;
    };

    services.authelia.instances."${cfg.authelia.domain}" = {
      enable = true;

      user  = "authelia";
      group = "authelia";

      # https://www.authelia.com/configuration/methods/secrets/#environment-variables
      environmentVariables.AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = "%d/ldap_password";
      environmentVariables.AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "%d/storage_encryption_key";
      environmentVariables.AUTHELIA_SESSION_SECRET_FILE = "%d/session_secret";
      environmentVariables.AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = "%d/jwt_secret";
      environmentVariables.AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = "%d/oidc_hmac_secret";
      environmentVariables.AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = "%d/smtp_password";

      environmentVariables.X_AUTHELIA_CONFIG_FILTERS = "template";

      settings.log.level = "info";

      settings.theme = "dark";
      settings.telemetry.metrics.enabled = true;
      settings.server.address = "unix:///run/authelia/authelia.sock?umask=0117";
      settings.server.endpoints.authz.forward-auth.implementation = "ForwardAuth";

      settings.default_2fa_method = "totp";

      settings.authentication_backend = {
        refresh_interval = "1m";

        ldap = {
          implementation = "lldap";
          address = "ldap://${config.services.lldap.settings.ldap_host}:${toString config.services.lldap.settings.ldap_port}"; # FIXME
          base_dn = cfg.lldap.baseDN;
          user = "uid=svc_authelia,ou=people,${cfg.lldap.baseDN}";
          users_filter = ''(&(|({username_attribute}={input})({mail_attribute}={input}))(objectClass=person)(memberOf=cn=SSO Users,ou=groups,${cfg.lldap.baseDN}))'';
        };

        # NB: Make sure the user is in the lldap_password_manager group
        password_reset.disable = false;
        password_change.disable = false;
      };

      settings.storage.postgres = {
        address = "unix:///var/run/postgresql";
        servers = [];
        database = "authelia";
        username = "authelia";
        schema = "public";
      };

      settings.totp = {
        disable = false;
        issuer = totpIssuer;
      };

      settings.webauthn = {
        disable = false;
        display_name = webauthnDisplayName;
      };

      settings.duo_api = {
        disable = true;
      };

      # TODO: maybe configure settings.ntp?

      settings.definitions = {
        network.internal = cfg.localNetworks;
      };

      # NB: This does _NOT_ affect OIDC clients.
      settings.access_control = {
        default_policy = "deny";

        rules = [
          ##
          # Navidrome
          # - Because the Subsonic API is shit, we need to bypass auth on the /rest/* endpoints and Navidrome handle it
          #   with the user's internal password. Except for the WebUI's /rest/* requests, which needs the same auth as the
          #   rest of it.
          ##
          {
            # Force the WebUI's Subsonic's requests through one factor
            domain = "music.vs49688.net";
            policy = "one_factor";
            resources = [
              "^/rest$"
              "^/rest/"
              "^/share$"
              "^/share/"
            ];
            query = [
              [ { operator = "equal"; key = "c"; value = "NavidromeUI"; } ]
            ];
          }
          {
            domain = "music.vs49688.net";
            policy = "bypass";
            resources = [
              "^/rest$"
              "^/rest/"
              "^/share$"
              "^/share/"
            ];
          }
          {
            domain = "music.vs49688.net";
            policy = "one_factor";
          }

          ##
          # Allow SSO Users to access DocSpell.
          # This should only be used from the public internet.
          ##
          {
            domain = "docs.vs49688.net";
            policy = "two_factor";
            subject = [
              "group:SSO Users"
            ];
          }
          {
            domain = "docs.vs49688.net";
            policy = "deny";
          }

          ##
          # Allow SSO Users to access Open WebUI.
          # This should only be used from the public internet.
          ##
          {
            domain = "chat.vs49688.net";
            policy = "two_factor";
            subject = [
              "group:SSO Users"
            ];
          }
          {
            domain = "chat.vs49688.net";
            policy = "deny";
          }

          ##
          # NVR
          ##
          {
            domain = "nvr.vs49688.net";
            policy = "one_factor";
            subject = [
              "group:NVR Admins"
              "group:NVR Viewers"
            ];
          }
          {
            domain = "nvr.vs49688.net";
            policy = "deny";
          }

          ##
          # Allow 2FA'd users access LLDAP Web UI.
          ##
          {
            domain = cfg.lldap.host;
            policy = "two_factor";
          }

          ##
          # Allow Network Admins users access the Unifi Controller.
          ##
          {
            domain = "unifi.vs49688.net";
            policy = "two_factor";
            subject = [
              "group:Network Admins"
            ];
          }

          ##
          # Allow "zane" access to HLDS.
          ##
          {
            domain = "hl.vs49688.net";
            subject = [
              "user:zane"
            ];
            policy = "one_factor";
            resources = [
              "^/cli$"
              "^/cli/"
            ];
          }

          ##
          # Allow "zane" access to transmission.
          ##
          {
            domain = "cadance.vs49688.net";
            subject = [
              "user:zane"
            ];
            policy = "one_factor";
            resources = [
              "^/transmission$"
              "^/transmission/"
            ];
          }

          ##
          # Allow "zane" access to Syncthing, require two factor.
          ##
          {
            domain = "cadance.vs49688.net";
            subject = [
              "user:zane"
            ];
            policy = "two_factor";
            resources = [
              "^/sync$"
              "^/sync/"
            ];
          }

          ##
          # Deny everyone else.
          ##
          {
            domain = "cadance.vs49688.net";
            policy = "deny";
            resources = [
              "^/transmission$"
              "^/transmission/"
              "^/sync$"
              "^/sync/"
            ];
          }

          ##
          # Everything else is fair-game.
          ##
          {
            domain = "cadance.vs49688.net";
            policy = "bypass";
          }

        ];
      };

      settings.session = {
        redis.host = config.services.redis.servers.authelia.unixSocket;

        # https://www.authelia.com/configuration/prologue/common/#duration
        expiration = "1w";
        inactivity = "1d";
        remember_me = "1M";

        cookies = [
          {
            name = "authelia_session";
            domain = cfg.authelia.domain;
            authelia_url = "https://${cfg.authelia.host}";
          }
        ];
      };

      settings.notifier.smtp = {
        address = cfg.authelia.smtpAddress;
        username = cfg.authelia.smtpUsername;
        sender = cfg.authelia.smtpSender;
      };

      secrets.manual = true; # DIY

      settings.identity_providers.oidc.cors = {
        endpoints = [
          "authorization"
          "token"
          "revocation"
          "introspection"
        ];
        allowed_origins = [
          "https://${cfg.authelia.host}"
        ];

        allowed_origins_from_client_redirect_uris = false;
      };

      settingsFiles = [
        # Nix's YAML generator can't handle these
        (pkgs.writeTextFile {
          name = "authelia-jwks.yml";
          text = ''
            identity_providers:
              oidc:
                jwks:
                  - algorithm: RS256
                    use: sig
                    key: {{ secret "/run/credentials/${autheliaServiceName}.service/oidc_jwks_key" | mindent 10 "|" | msquote }}
          '';
        })
        "/run/credentials/${autheliaServiceName}.service/clients.yml"
      ];
    };

    systemd.services."${autheliaServiceName}" = {
      requires = [
        "postgresql.target"
      ];

      serviceConfig = {
        LoadCredential = [
          "jwt_secret:${cfg.authelia.jwtSecretFile}"
          "storage_encryption_key:${cfg.authelia.storageEncryptionKeyFile}"
          "session_secret:${cfg.authelia.sessionSecretFile}"
          "ldap_password:${cfg.authelia.ldapPasswordFile}"
          "oidc_hmac_secret:${cfg.authelia.oidcHmacSecretFile}"
          "oidc_jwks_key:${cfg.authelia.jwksKey}"
          "smtp_password:${cfg.authelia.smtpPasswordFile}"
          "clients.yml:${cfg.authelia.clientsYml}"
        ];

        RuntimeDirectory = "authelia";

        SupplementaryGroups = [
          config.services.redis.servers.authelia.group
        ];
      };
    };

    services.caddy.virtualHosts."${cfg.authelia.host}".extraConfig = ''
      encode zstd gzip

      reverse_proxy unix//run/authelia/authelia.sock {
        header_up X-Real-Ip {remote_host}
      }
    '';

    services.caddy.virtualHosts."${cfg.lldap.host}".extraConfig = ''
      forward_auth unix//run/authelia/authelia.sock {
        uri /api/authz/forward-auth
      }

      reverse_proxy http://${config.services.lldap.settings.http_host}:${toString config.services.lldap.settings.http_port}
    '';
  };
}
