{ config, pkgs, lib, utils, ... }:
let
  cfg = config.cadance.backup;

  iniFormat = pkgs.formats.ini {};

  rcloneProfileName = "cadance-backup";

  rcloneConf = iniFormat.generate "rclone.conf" {
    "${rcloneProfileName}" = {
      type = "s3";
      provider = "AWS";
      env_auth = true;
      region = "ap-southeast-2";
      location_constraint = "ap-southeast-2";
      acl = "private";
      server_side_encryption = "AES256";
    };
  };

  rcloneSync = src: dst: let
    args = [
      "sync"
      "--config=${rcloneConf}"
      src
      "${rcloneProfileName}:${dst}"
    ];
  in
    "${pkgs.rclone}/bin/rclone ${utils.escapeSystemdExecArgs args}"
  ;

  # NB: Add "-vv --dump bodies" to rclone for extra logs
in
{
  options.cadance.backup = with lib; {
    enable = mkOption {
      type    = types.bool;
      default = false;
    };

    startAt = mkOption {
      default = "*-*-* 02:00:00";
      type    = types.str;
    };

    backupUser = mkOption {
      type = types.str;
      default = "backup";
      example = "backup";
    };

    resticTokenFile = mkOption {
      type = types.str;
    };

    rcloneConfig = mkOption {
      readOnly = true;
      type = types.package;
      default = rcloneConf;
      description = "Generated rclone config file";
    };

    awsProfile = mkOption {
      type = types.str;
    };

    awsSharedCredentialsFile = mkOption {
      type = types.str;
    };

    s3Bucket = mkOption {
      type = types.str;
    };

    offlineimap = mkOption {
      type = types.submodule {
        options = {
          remoteHost = mkOption {
            type = types.str;
          };

          remoteUser = mkOption {
            type = types.str;
          };

          passwordFile = mkOption {
            type = types.str;
          };
        };
      };
    };
  };

  config = let
    defaultServiceConfig = {
      RemoveIPC = true;
      CapabilityBoundingSet = "";
      ProtectClock = true;
      ProtectKernelLogs = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      ProtectHostname = true;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectProc = "invisible";
      ProtectHome = true;
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallFilter = [ "@system-service" "~@privileged" "@chown" ];
      SystemCallArchitectures = "native";
      UMask = "0027";
    };
  in lib.mkIf cfg.enable {

    ##
    # Create a dedicated backup user.
    ##
    users.groups.${cfg.backupUser}  = {};
    users.users.${cfg.backupUser} = {
      isSystemUser = true;
      group = cfg.backupUser;
      home = "/data/homes/backup";
      createHome = true;
    };

    # Grant it RO access to postgres data.
    services.postgresql.ensureUsers = [
      { name = cfg.backupUser; ensureRoles = [ "pg_read_all_data" ]; }
    ];

    ##
    # Gitea/Forgejo Backup
    ##
    users.users.${config.services.forgejo.user}.homeMode = "0750";

    systemd.services."git-backup" = let
      forgejoConfig = config.services.forgejo;
    in {
      startAt   = cfg.startAt;
      onFailure = [ "notify-email@%n.service" ];

      confinement.enable   = true;
      confinement.mode     = "full-apivfs";
      confinement.binSh    = "${pkgs.bash}/bin/sh";
      confinement.configureNetworking = true;

      requires = [ "postgresql.target" ];

      environment = {
        FORGEJO_CUSTOM = config.systemd.services.forgejo.environment.FORGEJO_CUSTOM;
        FORGEJO_WORK_DIR = config.systemd.services.forgejo.environment.FORGEJO_WORK_DIR;
      };

      environment.AWS_PROFILE = cfg.awsProfile;
      environment.AWS_SHARED_CREDENTIALS_FILE = "%d/aws_shared_credentials_file";

      serviceConfig = lib.recursiveUpdate defaultServiceConfig {
        LoadCredential = [
          "password:${cfg.resticTokenFile}"
          "aws_shared_credentials_file:${cfg.awsSharedCredentialsFile}"
        ];

        Type = "oneshot";

        User  = cfg.backupUser;
        Group = cfg.backupUser;

        BindReadOnlyPaths = [
          "/run/postgresql" # For Postgres socket
          "/etc/passwd"     # Needed for peer auth
          forgejoConfig.stateDir
        ];

        BindPaths = [
          config.users.users.${cfg.backupUser}.home # For duplicity cache/GPG
          "/storage/SyncRoot/Backups/gitea"         # local backup destination
        ];

        SupplementaryGroups = [
          config.users.users.${forgejoConfig.user}.group
        ];

        ExecStart = let
          restic = "${pkgs.restic}/bin/restic --repo /storage/SyncRoot/Backups/gitea --password-file \${CREDENTIALS_DIRECTORY}/password";
        in [
          "${pkgs.postgresql}/bin/pg_dump --no-password ${forgejoConfig.database.name} --file=/tmp/forgejo.sql"
          "${restic} backup --exclude '**/tmp_objdir-*/' /tmp/forgejo.sql /var/lib/forgejo/custom /var/lib/forgejo/data /var/lib/forgejo/repositories"
          "${restic} forget --keep-within 14d --prune"
          (rcloneSync "/storage/SyncRoot/Backups/gitea" "${cfg.s3Bucket}/gitea")
        ];
      };

      unitConfig.RequiresMountsFor = [ forgejoConfig.stateDir "/storage" ];
    };

    ##
    # PostgreSQL Backup
    ##
    systemd.services."pg-backup" = {
      startAt   = cfg.startAt;
      onFailure = [ "notify-email@%n.service" ];

      confinement.enable   = true;
      confinement.mode     = "full-apivfs";
      confinement.binSh    = "${pkgs.bash}/bin/sh"; # pg_dumpall uses popen(), which needs a shell
      confinement.configureNetworking = true;

      requires = [ "postgresql.target" ];

      environment.AWS_PROFILE = cfg.awsProfile;
      environment.AWS_SHARED_CREDENTIALS_FILE = "%d/aws_shared_credentials_file";

      serviceConfig = lib.recursiveUpdate defaultServiceConfig {
        LoadCredential = [
          "password:${cfg.resticTokenFile}"
          "aws_shared_credentials_file:${cfg.awsSharedCredentialsFile}"
        ];
        Type = "oneshot";

        User  = cfg.backupUser;
        Group = cfg.backupUser;

        BindReadOnlyPaths = [
          "/run/postgresql" # For Postgres socket
          "/etc/passwd"     # Needed for peer auth
        ];

        BindPaths = [
          config.users.users.${cfg.backupUser}.home # For duplicity cache/GPG
          "/storage/SyncRoot/Backups/postgresql"    # local backup destination
        ];

        ExecStart = let
          restic = "${pkgs.restic}/bin/restic --repo /storage/SyncRoot/Backups/postgresql --password-file \${CREDENTIALS_DIRECTORY}/password";
        in [
          "${pkgs.postgresql}/bin/pg_dumpall --no-password --file=/tmp/dump.sql"
          "${restic} backup /tmp/dump.sql"
          "${restic} forget --keep-within 14d --prune"
          (rcloneSync "/storage/SyncRoot/Backups/postgresql" "${cfg.s3Bucket}/postgresql")
        ];
      };

      unitConfig.RequiresMountsFor = [ "/storage" ];
    };

    ##
    # Navidrome Backup
    ##
    systemd.services."navidrome-backup" = let
      dataFolder = config.services.navidrome.settings.DataFolder;
    in {
      startAt = "*-*-* 03:00:00";
      onFailure = [ "notify-email@%n.service" ];

      environment.AWS_PROFILE = cfg.awsProfile;
      environment.AWS_SHARED_CREDENTIALS_FILE = "%d/aws_shared_credentials_file";

      serviceConfig = lib.recursiveUpdate defaultServiceConfig {
        LoadCredential = [
          "password:${cfg.resticTokenFile}"
          "aws_shared_credentials_file:${cfg.awsSharedCredentialsFile}"
        ];

        Type = "oneshot";

        User = cfg.backupUser;
        Group = cfg.backupUser;

        ProtectSystem = "strict";

        BindPaths = [
          "/storage/SyncRoot/Backups/navidrome"
        ];

        BindReadOnlyPaths = [
          dataFolder
        ];

        RuntimeDirectory = "navidrome-backup";
        RuntimeDirectoryMode = "0700";

        ExecStart = let
          restic = "${lib.getExe pkgs.restic} --repo /storage/SyncRoot/Backups/navidrome --password-file \${CREDENTIALS_DIRECTORY}/password";

          dumpArgs = [
            "-readonly"
            "--"
            "${dataFolder}/navidrome.db"
            ".output /run/navidrome-backup/navidrome.sql"
            ".dump"
          ];
        in [
          "+${lib.getExe pkgs.sqlite} ${utils.escapeSystemdExecArgs dumpArgs}"
          "+${pkgs.coreutils}/bin/chown backup: /run/navidrome-backup/navidrome.sql"
          "${restic} backup /run/navidrome-backup/navidrome.sql"
          "${restic} forget --keep-within 14d --prune"
          (rcloneSync "/storage/SyncRoot/Backups/navidrome" "${cfg.s3Bucket}/navidrome")
        ];
      };

      unitConfig.RequiresMountsFor = [ dataFolder "/storage" ];
    };

    ##
    # Nextcloud Backup
    ##
    systemd.services."nextcloud-backup" = let
      occ = config.services.nextcloud.occ;
    in {
      startAt = "*-*-* 03:00:00";
      onFailure = [ "notify-email@%n.service" ];
      requires = [ "postgresql.target" ];

      environment.AWS_PROFILE = cfg.awsProfile;
      environment.AWS_SHARED_CREDENTIALS_FILE = "%d/aws_shared_credentials_file";

      serviceConfig = lib.recursiveUpdate defaultServiceConfig {
        LoadCredential = [
          "password:${cfg.resticTokenFile}"
          "aws_shared_credentials_file:${cfg.awsSharedCredentialsFile}"
        ];

        Type = "oneshot";

        User = cfg.backupUser;
        Group = cfg.backupUser;
        SupplementaryGroups = [ "nextcloud" ];

        ProtectSystem = "strict";

        BindPaths = [
          config.users.users.${cfg.backupUser}.home # For duplicity cache/GPG
          "/storage/SyncRoot/Backups/nextcloud"     # local backup destination
          config.services.nextcloud.datadir         # Needs R/W to enable maintenance mode
        ];

        ExecStartPre = [ "+${occ}/bin/nextcloud-occ maintenance:mode --on" ];
        ExecStart = let
          restic = "${pkgs.restic}/bin/restic --repo /storage/SyncRoot/Backups/nextcloud --password-file \${CREDENTIALS_DIRECTORY}/password";
        in [
          "${pkgs.postgresql}/bin/pg_dump --no-password nextcloud --file=/tmp/nextcloud.sql"
          "${restic} backup /tmp/nextcloud.sql /var/lib/nextcloud/config /var/lib/nextcloud/store-apps /var/lib/nextcloud/data"
          "${restic} forget --keep-within 14d --prune"
          (rcloneSync "/storage/SyncRoot/Backups/nextcloud" "${cfg.s3Bucket}/nextcloud")
        ];
        ExecStopPost = [ "+${occ}/bin/nextcloud-occ maintenance:mode --off" ];
      };

      unitConfig.RequiresMountsFor = [ config.services.nextcloud.datadir "/storage" ];
    };

    ##
    # /var/www backup
    ##
    systemd.services."www-backup" = {
      startAt = cfg.startAt;
      onFailure = [ "notify-email@%n.service" ];

      confinement.enable   = true;
      confinement.mode     = "full-apivfs";
      confinement.binSh    = "${pkgs.bash}/bin/sh";
      confinement.configureNetworking = true;

      environment.AWS_PROFILE = cfg.awsProfile;
      environment.AWS_SHARED_CREDENTIALS_FILE = "%d/aws_shared_credentials_file";

      serviceConfig = lib.recursiveUpdate defaultServiceConfig {
        LoadCredential = [
          "password:${cfg.resticTokenFile}"
          "aws_shared_credentials_file:${cfg.awsSharedCredentialsFile}"
        ];

        Type = "oneshot";

        User  = cfg.backupUser;
        Group = cfg.backupUser;

        BindReadOnlyPaths = [
          "/var/www"
        ];

        BindPaths = [
          config.users.users.${cfg.backupUser}.home # For duplicity cache/GPG
          "/storage/SyncRoot/Backups/www"           # local backup destination
        ];

        ExecStart = let
          restic = "${pkgs.restic}/bin/restic --repo /storage/SyncRoot/Backups/www --password-file \${CREDENTIALS_DIRECTORY}/password";
        in [
          "${restic} backup /var/www"
          "${restic} forget --keep-within 14d --prune"
          (rcloneSync "/storage/SyncRoot/Backups/www" "${cfg.s3Bucket}/www")
        ];
      };

      unitConfig.RequiresMountsFor = [ "/storage" "/var/www" ];
    };

    ##
    # /var/lib/bitwarden_rs backup
    ##
    systemd.services."vaultwarden-backup" = {
      startAt = cfg.startAt;
      onFailure = [ "notify-email@%n.service" ];

      confinement.enable   = true;
      confinement.mode     = "full-apivfs";
      confinement.binSh    = "${pkgs.bash}/bin/sh";
      confinement.configureNetworking = true;

      environment.AWS_PROFILE = cfg.awsProfile;
      environment.AWS_SHARED_CREDENTIALS_FILE = "%d/aws_shared_credentials_file";

      serviceConfig = lib.recursiveUpdate defaultServiceConfig {
        LoadCredential = [
          "password:${cfg.resticTokenFile}"
          "aws_shared_credentials_file:${cfg.awsSharedCredentialsFile}"
        ];

        Type = "oneshot";

        User  = cfg.backupUser;
        Group = cfg.backupUser;

        BindReadOnlyPaths = [
          "/var/lib/bitwarden_rs"
        ];

        BindPaths = [
          config.users.users.${cfg.backupUser}.home
          "/storage/SyncRoot/Backups/vaultwarden"
        ];

        SupplementaryGroups = [
          "vaultwarden"
        ];

        ExecStart = let
          restic = "${pkgs.restic}/bin/restic --repo /storage/SyncRoot/Backups/vaultwarden --password-file \${CREDENTIALS_DIRECTORY}/password";
        in [
          "${restic} backup /var/lib/bitwarden_rs"
          "${restic} forget --keep-within 14d --prune"
          (rcloneSync "/storage/SyncRoot/Backups/vaultwarden" "${cfg.s3Bucket}/vaultwarden")
        ];
      };

      unitConfig.RequiresMountsFor = [ "/storage" "/var/lib/bitwarden_rs" ];
    };


    systemd.services."mail-backup" = let
      format = pkgs.formats.ini {};

      configFile = format.generate "offlineimaprc" {
        general = {
          accounts = "main";
          fsync = "true";
        };

        "Account main" = {
          localrepository = "main-local";
          remoterepository = "main-remote";
        };

        "Repository main-local" = {
          type = "Maildir";
          localfolders = "~/mail-backup";
        };

        "Repository main-remote" = {
          type = "IMAP";
          remotehost = cfg.offlineimap.remoteHost;
          remoteuser = cfg.offlineimap.remoteUser;
          ssl = "yes";
          readonly = "True";
          sslcacertfile = "OS-DEFAULT";
          folderfilter = "lambda fn: fn not in ['Development/ffmpeg-devel', 'Development/ntfs3']";
        };
      };
    in {
      startAt = cfg.startAt;
      onFailure = [ "notify-email@%n.service" ];

      confinement.enable   = true;
      confinement.mode     = "full-apivfs";
      confinement.binSh    = "${pkgs.bash}/bin/sh";
      confinement.configureNetworking = true;

      environment.AWS_PROFILE = cfg.awsProfile;
      environment.AWS_SHARED_CREDENTIALS_FILE = "%d/aws_shared_credentials_file";

      serviceConfig = lib.recursiveUpdate defaultServiceConfig {
        LoadCredential = [
          "password-offlineimap:${cfg.offlineimap.passwordFile}"
          "password-restic:${cfg.resticTokenFile}"
          "aws_shared_credentials_file:${cfg.awsSharedCredentialsFile}"
        ];

        Type = "oneshot";

        User  = cfg.backupUser;
        Group = cfg.backupUser;

        BindPaths = [
          "/data/homes/backup"
          "/storage/SyncRoot/Backups/mail"
        ];

        ExecStart = let
          restic = "${pkgs.restic}/bin/restic --repo /storage/SyncRoot/Backups/mail --password-file \${CREDENTIALS_DIRECTORY}/password-restic";
        in [
          ''${pkgs.offlineimap}/bin/offlineimap -c ${configFile} -k "Repository main-remote:remotepassfile=''${CREDENTIALS_DIRECTORY}/password-offlineimap" -o -1''
          "${restic} backup /data/homes/backup/mail-backup"
          "${restic} forget --keep-within 14d --prune"
          (rcloneSync "/storage/SyncRoot/Backups/mail" "${cfg.s3Bucket}/mail")
        ];
      };

      unitConfig.RequiresMountsFor = [ "/data/homes/backup" "/storage" ];
    };
  };
}
