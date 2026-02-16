{ config, pkgs, lib, ... }:
let
  cfg = config.cadance.immich;
in
{
  options.cadance.immich = with lib; {
    enable = mkEnableOption "Enable CADANCE Immich";

    hostName = mkOption {
      type = types.str;
    };

    smtpFrom = mkOption {
      type = types.str;
      example = "Immich <noreply@example.com>";
    };

    smtpHost = mkOption {
      type = types.str;
      example = "smtp.example.com";
    };

    smtpUsername = mkOption {
      type = types.str;
      example = "noreply@example.com";
    };

    smtpSecretFile = mkOption {
      type = types.str;
    };

    oauthClientId = mkOption {
      type = types.str;
    };

    oauthIssuerUrl = mkOption {
      type = types.str;
    };

    oauthClientSecretPath = mkOption {
      type = types.str;
    };

    oauthButtonText = mkOption {
      type = types.str;
      example = "Login with SSO";
    };
  };

  config = lib.mkIf cfg.enable {
    services.immich = {
      enable = true;

      machine-learning.enable = false;

      database.enable = true;
      database.enableVectors = false;
      database.enableVectorChord = true;

      settings.server.externalDomain = "https://${cfg.hostName}";
      settings.newVersionCheck.enabled = false;
      settings.backup.database.enabled = false; # Handled externally

      accelerationDevices = [
        "/dev/dri/renderD128"
      ];

      settings.ffmpeg.accel = "vaapi";
      settings.ffmpeg.accelDecode = true;

      settings.job.thumbnailGeneration.concurrency = 16;
      settings.job.metadataExtraction.concurrency = 16;

      settings.machineLearning.enabled = false;
      settings.machineLearning.availabilityChecks.enabled = false;
      settings.machineLearning.clip.enabled = false;
      settings.machineLearning.duplicateDetection.enabled = false;
      settings.machineLearning.facialRecognition.enabled = false;

      settings.notifications.smtp.enabled = true;
      settings.notifications.smtp.from = cfg.smtpFrom;
      settings.notifications.smtp.transport.host = cfg.smtpHost;
      settings.notifications.smtp.transport.port = 587; # Change to 465 after 2.1.0
      settings.notifications.smtp.transport.username = cfg.smtpUsername;
      settings.notifications.smtp.transport.password._secret = cfg.smtpSecretFile;

      settings.passwordLogin.enabled = lib.mkDefault false;

      settings.oauth.autoLaunch = true;
      settings.oauth.autoRegister = true;
      settings.oauth.buttonText = cfg.oauthButtonText;
      settings.oauth.clientId = cfg.oauthClientId;
      settings.oauth.enabled = true;
      settings.oauth.issuerUrl = cfg.oauthIssuerUrl;
      settings.oauth.scope = "openid email profile";
      settings.oauth.signingAlgorithm = "RS256";
      settings.oauth.profileSigningAlgorithm = "none";
      settings.oauth.storageLabelClaim = "preferred_username";

      settings.oauth.clientSecret._secret = cfg.oauthClientSecretPath;
    };

    systemd.services.immich-server.unitConfig.RequiresMountsFor = [
      config.services.immich.mediaLocation
    ];

    services.caddy.virtualHosts."${cfg.hostName}".extraConfig = ''
      reverse_proxy http://${config.services.immich.host}:${toString config.services.immich.port}
    '';
  };
}
