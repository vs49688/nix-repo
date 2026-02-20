{ docspell, ... }:
{ config, pkgs, lib, ... }:
let
  cfg = config.cadance.docspell;

  ftsConfig = {
    enabled = true;
    backend = "postgresql";
    postgresql.use-default-connection = true;
  };
in
{
  options.cadance.docspell = with lib; {
    enable = lib.mkEnableOption "Docspell";

    containerName = mkOption {
      type    = types.str;
      default = "docspell";
    };

    hostAddress = mkOption {
      type    = types.str;
    };

    localAddress = mkOption {
      type    = types.str;
    };

    virtualHost = mkOption {
      type    = types.str;
      example = "docs.example.com";
    };

    restserverAppName = mkOption {
      type = types.str;
    };

    restserverAppId = mkOption {
      type = types.str;
    };

    joexAppId = mkOption {
      type = types.str;
    };

    jdbcUrl = mkOption {
      type = types.str;
    };

    jdbcUser = mkOption {
      type = types.str;
    };

    jdbcPassword = mkOption {
      type = types.str;
    };

    adminTokenFile = mkOption {
      type = types.str;
    };

    oidcDisplayName = mkOption {
      type = types.str;
      example = "auth.example.com";
    };

    oidcClientId = mkOption {
      type = types.str;
      example = "00000000-0000-0000-0000-000000000000";
    };

    oidcAutheliaServer = mkOption {
      type = types.str;
      example = "auth.example.com";
    };

    oidcClientSecretFile = mkOption {
      type = types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.nat.internalInterfaces   = [ "ve-${cfg.containerName}" ];
    networking.networkmanager.unmanaged = [ "interface-name:ve-${cfg.containerName}" ];

    services.caddy.virtualHosts.${cfg.virtualHost}.extraConfig = ''
      reverse_proxy http://${cfg.localAddress}:7880
    '';

    containers.${cfg.containerName} = {
      autoStart       = true;
      ephemeral       = true;
      privateNetwork  = true;
      hostAddress     = cfg.hostAddress;
      localAddress    = cfg.localAddress;
      timeoutStartSec = "10min";

      bindMounts."${cfg.adminTokenFile}" = {
        isReadOnly = true;
      };

      bindMounts."${cfg.oidcClientSecretFile}" = {
        isReadOnly = true;
      };

      config = { config, pkgs, ... }: {
        nixpkgs = {
          overlays = [
            docspell.overlays.default
          ];
        };

        imports = [
          docspell.nixosModules.joex
          docspell.nixosModules.server
        ];

        fonts.fontconfig.useEmbeddedBitmaps = true;
        fonts.enableDefaultPackages = true;
        fonts.packages = with pkgs; [
          ipafont
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-monochrome-emoji
          noto-fonts-color-emoji
          twemoji-color-font
        ];

        networking.firewall.allowedTCPPorts = [ 7880 ];

        services.docspell-restserver = {
          enable = true;

          app-name = cfg.restserverAppName;
          app-id   = cfg.restserverAppId;

          bind.address = "0.0.0.0";
          bind.port    = 7880;

          internal-url = "http://127.0.0.1:7880";
          base-url     = "https://${cfg.virtualHost}/";

          jvmArgs  = [
            "-J-Xmx4096M"
            "-Dorg.apache.pdfbox.rendering.UsePureJavaCMYKConversion=true"
            "-Dconfig.override_with_env_vars=true"
          ];

          # Disable these, we don't need them
          integration-endpoint.enabled = false;
          admin-endpoint.secret = "";

          full-text-search = ftsConfig;

          backend.signup.mode = "closed";

          backend.jdbc.url = cfg.jdbcUrl;
          backend.jdbc.user = cfg.jdbcUser;
          backend.jdbc.password = cfg.jdbcPassword;

          auth = {
            session-valid = "1 hour";

            remember-me = {
              enabled = true;
              valid = "30 days";
            };

            on-account-source-conflict = "convert";
          };

          extraConfig = {
            oidc-auto-redirect = true;

            files = {
              default-store = "database";
              stores.database.enabled = true;
            };
          };
        };

        systemd.services.docspell-restserver = {
          environment = {
            CONFIG_FORCE_docspell_server_openid_0_enabled = "true";
            CONFIG_FORCE_docspell_server_openid_0_display = cfg.oidcDisplayName;
            CONFIG_FORCE_docspell_server_openid_0_collective__key = "lookup:preferred_username"; # FIXME:
            CONFIG_FORCE_docspell_server_openid_0_user__key = "preferred_username";

            CONFIG_FORCE_docspell_server_openid_0_provider_provider__id = "authelia";
            CONFIG_FORCE_docspell_server_openid_0_provider_client__id = cfg.oidcClientId;
            CONFIG_FORCE_docspell_server_openid_0_provider_scope = "openid profile groups email";
            CONFIG_FORCE_docspell_server_openid_0_provider_authorize__url = "https://${cfg.oidcAutheliaServer}/api/oidc/authorization";
            CONFIG_FORCE_docspell_server_openid_0_provider_token__url = "https://${cfg.oidcAutheliaServer}/api/oidc/token";
            CONFIG_FORCE_docspell_server_openid_0_provider_user__url = "https://${cfg.oidcAutheliaServer}/api/oidc/userinfo";
            CONFIG_FORCE_docspell_server_openid_0_provider_logout__url = "https://${cfg.oidcAutheliaServer}/logout?rd=https://${cfg.virtualHost}";
            CONFIG_FORCE_docspell_server_openid_0_provider_sign__key = "";
            CONFIG_FORCE_docspell_server_openid_0_provider_sig__algo = "RS256";
          };

          serviceConfig.LoadCredential = [
            "admin_token:${cfg.adminTokenFile}"
            "oidc_client_secret:${cfg.oidcClientSecretFile}"
          ];

          # https://github.com/lightbend/config?tab=readme-ov-file#optional-system-or-env-variable-overrides
          script = lib.mkBefore ''
            export CONFIG_FORCE_docspell_server_admin__endpoint_secret=$(cat ''${CREDENTIALS_DIRECTORY}/admin_token)
            export CONFIG_FORCE_docspell_server_openid_0_provider_client__secret=$(cat ''${CREDENTIALS_DIRECTORY}/oidc_client_secret)
          '';
        };

        services.docspell-joex = {
          enable = true;

          app-id = cfg.joexAppId;

          bind.address = "127.0.0.1";
          bind.port    = 7878;

          base-url = "http://127.0.0.1:7878";
          jvmArgs  = [
            "-J-Xmx4096M"
            "-Dorg.apache.pdfbox.rendering.UsePureJavaCMYKConversion=true"
            "-Dconfig.override_with_env_vars=true"
          ];

          jdbc.url = cfg.jdbcUrl;
          jdbc.user = cfg.jdbcUser;
          jdbc.password = cfg.jdbcPassword;

          full-text-search = ftsConfig;

          scheduler.pool-size = 4;
          convert.ocrmypdf.command.timeout = "30 minutes";
          convert.ocrmypdf.command.args = [
            "-l" "{{lang}}"
            "--skip-text"
            "--deskew"
            "--color-conversion-strategy" "RGB"
            "-j" "1"
            "{{infile}}"
            "{{outfile}}"
          ];

          convert.weasyprint.command.args =  [
            "--verbose"
            "--optimize-images" # lossless
            "--encoding" "{{encoding}}"
            "-"
            "{{outfile}}"
          ];
        };

        systemd.services.unoconv = {
          confinement.enable = true;
          confinement.mode = "full-apivfs";

          script = lib.mkForce "${pkgs.unoconv}/bin/unoconv --listener -v";
        };

        time.timeZone = "Australia/Brisbane";

        system.stateVersion = "21.11";
      };
    };
  };
}
