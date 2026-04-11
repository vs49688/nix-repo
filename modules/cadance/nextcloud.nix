{ lib, config, pkgs, ... }:
let
  cfg = config.cadance.nextcloud;
  nxCfg = config.services.nextcloud;
  ngCfg = config.services.nginx.virtualHosts."${nxCfg.hostName}";
in
{
  options.cadance.nextcloud = with lib; {
    enable = mkEnableOption "Enable CADANCE Nextcloud";

    hostName = mkOption {
      type = types.str;
      example = "nextcloud.example.com";
    };

    adminpassFile = mkOption {
      type = types.str;
    };

    package = mkOption {
      type = types.package;
    };
  };

  config = lib.mkIf cfg.enable {
    services.nextcloud = let
      nextcloud = cfg.package;
      apps = nextcloud.packages.apps;
    in {
      enable = true;
      https = true;
      hostName = cfg.hostName;
      package = nextcloud;

      extraAppsEnable = true;
      extraApps = {
        inherit (apps)
          bookmarks
          calendar
          contacts
          impersonate
          notes
          tasks
          deck
          user_oidc
        ;
      };

      enableImagemagick = true;

      maxUploadSize = "16G";

      config = {
        dbtype = "pgsql";
        dbname = "nextcloud";
        dbuser = "nextcloud";
        dbhost = "/var/run/postgresql";

        adminpassFile = cfg.adminpassFile;
      };

      settings.trusted_proxies = [ "127.0.0.1" ];
      settings.default_phone_region = "AU";

      settings."overwrite.cli.url" = "https://${nxCfg.hostName}";

      settings."preview_ffmpeg_path" = "${pkgs.ffmpeg-headless}/bin/ffmpeg";

      settings.allow_local_remote_servers = true;

      settings.user_oidc = {
        default_token_endpoint_auth_method = "client_secret_post";
      };

      phpOptions = {
        "opcache.interned_strings_buffer" = "32";
      };
    };

    systemd.services.nextcloud-setup = {
      unitConfig.RequiresMountsFor = [ "/var/lib/nextcloud" ];
      wants = [ "network-online.target" ];
    };

    services.phpfpm.pools.nextcloud.settings = {
      "listen.owner" = config.services.caddy.user;
      "listen.group" = config.services.caddy.group;
    };
    users.groups.nextcloud.members = [ "nextcloud" config.services.caddy.user ];

    systemd.services.phpfpm-nextcloud = {
      # confinement.enable = true;
      # confinement.mode = "full-apivfs";
      # confinement.configureNetworking = true;

      serviceConfig = {
        RemoveIPC = true;
        CapabilityBoundingSet = [ "CAP_SETGID" "CAP_SETUID" "CAP_CHOWN" ];
        ProtectClock = true;
        ProtectKernelLogs = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = false; # For PCRE JIT
        ProtectHostname = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectProc = "invisible";
        ProtectHome = true;
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        # RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6"; # Set by the NixOS module
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallFilter = [ "@system-service" "~@privileged" "@chown" "@setuid" ];
        SystemCallArchitectures = "native";

        TemporaryFileSystem = [ "/storage" "/data" ];

        # # Incompatible with confinement.
        # ProtectSystem = lib.mkForce false;
        # PrivateUsers = false;

        # BindReadOnlyPaths = [
        #   "/etc/passwd"
        #   "/etc/group"
        #   "${nxCfg.package}"
        # ];

        # BindPaths = [
        #   nxCfg.home
        # ];
      };
    };

    services.caddy.virtualHosts."${cfg.hostName}".extraConfig = ''
      # Enable gzip but do not remove ETag headers
      encode {
        zstd
        gzip 4

        minimum_length 256

        match {
          header Content-Type application/atom+xml
          header Content-Type application/javascript
          header Content-Type application/json
          header Content-Type application/ld+json
          header Content-Type application/manifest+json
          header Content-Type application/rss+xml
          header Content-Type application/vnd.geo+json
          header Content-Type application/vnd.ms-fontobject
          header Content-Type application/wasm
          header Content-Type application/x-font-ttf
          header Content-Type application/x-web-app-manifest+json
          header Content-Type application/xhtml+xml
          header Content-Type application/xml
          header Content-Type font/opentype
          header Content-Type image/bmp
          header Content-Type image/svg+xml
          header Content-Type image/x-icon
          header Content-Type text/cache-manifest
          header Content-Type text/css
          header Content-Type text/plain
          header Content-Type text/vcard
          header Content-Type text/vnd.rim.location.xloc
          header Content-Type text/vtt
          header Content-Type text/x-component
          header Content-Type text/x-cross-domain-policy
        }
      }

      header Referrer-Policy "no-referrer"
      header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;"
      header X-Content-Type-Options "nosniff"
      header X-Download-Options "noopen"
      header X-Frame-Options "SAMEORIGIN"
      header X-Permitted-Cross-Domain-Policies "none"
      header X-Robots-Tag "noindex, nofollow"
      header X-XSS-Protection "1; mode=block"

      redir /.well-known/carddav   /remote.php/dav/ 301
      redir /.well-known/caldav    /remote.php/dav/ 301
      redir /.well-known/webfinger /index.php/.well-known/webfinger 301
      redir /.well-known/nodeinfo  /index.php/.well-known/nodeinfo 301

      @store_apps path_regexp ^/store-apps
      root @store_apps ${nxCfg.home}

      root * ${ngCfg.root}

      @davClnt {
        header_regexp User-Agent ^DavClnt
        path /
      }

      redir @davClnt /remote.php/webdev{uri} 302


      @sensitive {
        # ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)
        path /build     /build/*
        path /tests     /tests/*
        path /config    /config/*
        path /lib       /lib/*
        path /3rdparty  /3rdparty/*
        path /templates /templates/*
        path /data      /data/*

        # ^/(?:\.|autotest|occ|issue|indie|db_|console)
        path /.*
        path /autotest*
        path /occ*
        path /issue*
        path /indie*
        path /db_*
        path /console*
      }
      respond @sensitive 404

      @legacy {
          path */ajax/*
      }
      rewrite @legacy /index.php{path}

      php_fastcgi unix/${config.services.phpfpm.pools.nextcloud.socket} {
        env modHeadersAvailable true      # Avoid sending the security headers twice
        env front_controller_active true  # Enable pretty urls

        capture_stderr
      }
      file_server
    '';
  };
}
