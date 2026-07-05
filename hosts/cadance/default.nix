{ config, pkgs, lib, ... }:
let
  noreplyEmail = config.cadance.settings.noreplyEmail;
  noreplyEmailFull = config.cadance.settings.noreplyEmailFull;

  notifyEmails = config.cadance.settings.notifyEmails;
  notifyEmailsFull = config.cadance.settings.notifyEmailsFull;

  musicMountPath = config.cadance.settings.musicMountPath;

  containerAddresses = let
    mkAddress = dot: {
      host  = "10.254.0.${toString dot}";
      local = "10.254.1.${toString dot}";
    };
  in {
    unifi          = mkAddress 2;
    docspell       = mkAddress 6;
    torrent        = mkAddress 8;
  };

  primaryUser = config.settings.primaryUser;

  defaultHashedPassword = "$6$BxuSRej5CnpDNrpD$WOFbzquMrmz4ulhVr6THPKID4HK1jwcv5DAtw5P4It8ZmfvwaCUIV2koEKwyattH2hyhHLqwGLO.HoLGNxzbJ.";

  caddyBlacklist = ''
    @blacklist not {
      remote_ip ${lib.concatStringsSep " " config.cadance.settings.localNetworks}
    }
  '';
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/settings
    ../../modules/ssh-totp.nix
    ../../modules/postgres-ensure-roles.nix
    ../../modules/cadance/settings.nix
    ../../modules/cadance/postgresql.nix
    ../../modules/cadance/auth.nix
    ../../modules/cadance/unifi.nix
    ../../modules/cadance/nextcloud.nix
    ../../modules/cadance/frigate.nix
    ../../modules/cadance/torrent.nix
    ../../modules/cadance/navidrome.nix
    ../../modules/cadance/immich.nix
    ../../modules/cadance/vaultwarden.nix
    ../../modules/cadance/ai.nix
    ../../modules/cadance/backup.nix
    ../../modules/cadance/forgejo.nix
    ../../modules/cadance/crypto.nix
    # NB: docspell is handled at the flake level
  ];

  nixpkgs.overlays = [
    (self: super: rec {
      cadance-mail = pkgs.writeShellScriptBin "mail.sh" ''
        #!${pkgs.runtimeShell}

        SENDMAIL=${pkgs.system-sendmail}/bin/sendmail
        SYSTEMCTL=${pkgs.systemd}/bin/systemctl

        if [ $# != 1 ]; then
          echo "Usage: $0 <service>"
          exit 2
        fi

        exec $SENDMAIL -f ${noreplyEmail} -i ${lib.strings.escapeShellArgs notifyEmails} <<EOF
        To: ${lib.strings.concatStringsSep ", " notifyEmailsFull}
        From: ${noreplyEmailFull}
        Subject: [CADANCE] [$1] failure email notification

        $($SYSTEMCTL status $1 --no-pager -l -n50)
        EOF
      '';
    })
  ];

  nix.settings.system-features = [
    "nixos-test"
    "benchmark"
    "big-parallel"
    "kvm"
    "gccarch-znver3"
    "gcctune-znver3"
  ];

  nix.useCadance = false; # We are CADANCE.

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 1;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = pkgs.linuxPackages_6_18;

  boot.blacklistedKernelModules = [ "nouveau" ];

  boot.initrd.availableKernelModules = [
    # basename $(readlink /sys/class/net/enp42s0/device/driver/module)
    "r8169"
    "amdgpu"
    "mpt3sas"
  ];

  boot.initrd.network = {
    enable = true;
    ssh = {
      enable         = true;
      port           = 2222;
      authorizedKeys = config.settings.primaryUser.authorizedKeys;

      # NB: These are copied into the nix store
      hostKeys = [
        "/boot/ssh_host_rsa_key"
        "/boot/ssh_host_ecdsa_key"
      ];
    };
  };

  # Write a .profile to /var/empty (root's home in the systemd initrd)
  # so that logging in over SSH automatically starts the password agent.
  boot.initrd.systemd.services.zfs-setup-root-profile = {
    description = "Prepare root .profile for ZFS unlocking via SSH";
    wantedBy = [ "initrd.target" ];
    before = [ "initrd-root-fs.target" ];
    unitConfig.DefaultDependencies = false;
    script = ''
      mkdir -p /var/empty
      echo "systemd-tty-ask-password-agent --watch" > /var/empty/.profile
    '';
    serviceConfig.Type = "oneshot";
  };

  boot.zfs.requestEncryptionCredentials = [ "cadance/private" "candystor/storage" "scratch/private" ];
  boot.zfs.forceImportAll = true; # Only adds the -f flag to "zpool import", doesn't import ALL pools.

  # These two are overridden privately.
  sops.defaultSopsFile = lib.mkDefault "/secrets/cadance.yaml";
  sops.validateSopsFiles = lib.mkDefault false;

  sops.age.sshKeyPaths = [
    "/data/root/ssh_host_ed25519_key"
  ];

  sops.secrets."open-webui/env" = {
    restartUnits = [ "open-webui.service" ];
  };

  sops.secrets."litellm/env" = {
    restartUnits = [ "litellm.service" ];
  };

  sops.secrets."nullmailer/remotes.conf" = {
    restartUnits = [ "nullmailer.service" ];

    owner = config.users.users.${config.services.nullmailer.user}.name;
    group = config.users.groups.${config.services.nullmailer.group}.name;
  };

  sops.secrets."immich/smtp_password" = {
    restartUnits = [ "immich-server.service" ];

    owner = config.users.users.${config.services.immich.user}.name;
    group = config.users.groups.${config.services.immich.group}.name;
  };

  sops.secrets."immich/oauth_client_secret" = {
    restartUnits = [ "immich-server.service" ];

    owner = config.users.users.${config.services.immich.user}.name;
    group = config.users.groups.${config.services.immich.group}.name;
  };

  sops.secrets."syncthing/cert.pem" = {
    restartUnits = [ "syncthing.service" ];

    owner = config.users.users.${config.services.syncthing.user}.name;
    group = config.users.groups.${config.services.syncthing.group}.name;
  };

  sops.secrets."syncthing/key.pem" = {
    restartUnits = [ "syncthing.service" ];

    owner = config.users.users.${config.services.syncthing.user}.name;
    group = config.users.groups.${config.services.syncthing.group}.name;
  };

  sops.secrets."nextcloud/adminpass" = {
    owner = config.users.users.nextcloud.name;
    group = config.users.groups.nextcloud.name;
  };


  sops.secrets."exporters/snmp_env" = {
    restartUnits = [ "prometheus-snmp-exporter.service" ];
  };

  sops.secrets."vaultwarden/env" = {
    restartUnits = [ "vaultwarden.service" ];

    owner = config.users.users.vaultwarden.name;
    group = config.users.groups.vaultwarden.name;
  };

  sops.secrets."backup/restic_token" = { };
  sops.secrets."backup/aws_shared_credentials_file" = {};

  sops.secrets."forgejo/mailpasswd" = {
    restartUnits = [ "forgejo.service" ];
  };

  sops.secrets."forgejo/runner_env" = {
    restartUnits = [ "gitea-runner-CADANCE.service" ];
  };

  sops.secrets."lldap/user_pass" = {
    restartUnits = [ "lldap.service" ];
  };

  sops.secrets."lldap/jwt_secret" = {
    restartUnits = [ "lldap.service" ];
  };

  sops.secrets."lldap/key_file" = {
    restartUnits = [ "lldap.service" ];

    format = "binary";
    sopsFile = lib.mkDefault "/secrets/lldap_server_key";
  };

  sops.secrets."authelia/ldap_password" = {
    restartUnits = [ "authelia-vs49688.net.service" ];
  };

  sops.secrets."authelia/jwt_secret" = {
    restartUnits = [ "authelia-vs49688.net.service" ];
  };

  sops.secrets."authelia/storage_encryption_key" = {
    restartUnits = [ "authelia-vs49688.net.service" ];
  };

  sops.secrets."authelia/session_secret" = {
    restartUnits = [ "authelia-vs49688.net.service" ];
  };

  sops.secrets."authelia/oidc_hmac_secret" = {
    restartUnits = [ "authelia-vs49688.net.service" ];
  };

  sops.secrets."authelia/oidc_jwks_key" = {
    restartUnits = [ "authelia-vs49688.net.service" ];
  };

  sops.secrets."authelia/smtp_password" = {
    restartUnits = [ "authelia-vs49688.net.service" ];
  };

  sops.secrets."authelia/clients.yml" = {
    restartUnits = [ "authelia-vs49688.net.service" ];
  };

  sops.secrets."grafana/oidc_client_secret" = {
    restartUnits = [ "grafana.service" ];
  };

  sops.secrets."navidrome/env" = {
    restartUnits = [ "navidrome.service" ];
  };

  sops.secrets."docspell/admin_token" = {
    restartUnits = [ "container@docspell.service" ];
  };

  sops.secrets."docspell/oidc_client_secret" = {
    restartUnits = [ "container@docspell.service" ];
  };

  sops.secrets."mail-backup/com-zanevaniperen-backup-cadance" = {};

  fileSystems."/" = {
    options       = [ "defaults" "size=25%" "mode=755" ];
  };

  fileSystems."/data".neededForBoot = true;

  fileSystems."/storage".options        = [ "nofail" "noatime" "nodiratime" "xattr" "posixacl" ];
  fileSystems."/downloads".options      = [ "nofail" "noatime" "nodiratime" "xattr" "posixacl" ];
  fileSystems.${musicMountPath}.options = [ "nofail" "noatime" "nodiratime" "xattr" "posixacl" ];

  fileSystems."/media/Collection1" = {
    neededForBoot = false;
    options       = [ "nofail" "noatime" "nodiratime" "xattr" "posixacl" ];
  };

  fileSystems."/media/infowars" = {
    neededForBoot = false;
    options       = [ "nofail" "noatime" "nodiratime" "xattr" "posixacl" ];
  };

  fileSystems."/media/scratch" = {
    neededForBoot = false;
    options       = [ "nofail" "noatime" "nodiratime" "xattr" "posixacl" ];
    depends       = [ "/boot" ];
  };

  fileSystems."/media/video" = {
    neededForBoot = false;
    options       = [ "nofail" "noatime" "nodiratime" ];
  };

  services.zfs.autoScrub = {
    enable   = true;
    interval = "*-*-01 02:00:00";
  };

  services.zfs.autoSnapshot = {
    enable = true;
    frequent = 8;
    monthly  = 2;
  };

  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = notifyEmails;
    ZED_NOTIFY_INTERVAL_SECS = 3600;
    ZED_NOTIFY_VERBOSE = false;
  };

  services.smartd = {
    enable = true;

    devices = [
      # Slot: M2_2
      { device = "/dev/disk/by-id/nvme-eui.002538453140a724"; }          # NVME

      { device = "/dev/disk/by-id/ata-WDC_WD43PURZ-74BWPY0_WD-WX12D24CXVAT"; } # Top 5 1/2" bay
      { device = "/dev/disk/by-id/ata-WDC_WD43PURZ-74BWPY0_WD-WX12D24CX7YL"; } # Bottom 5 1/2" bay

      { device = "/dev/disk/by-id/ata-SPCC_Solid_State_Disk_8B1807140FAB00035164"; } # Sitting somewhere
      { device = "/dev/disk/by-id/ata-SPCC_Solid_State_Disk_8B1807140FAB00035182"; } # Sitting somewhere

      { device = "/dev/disk/by-id/ata-WDC_WD101EFBX-68B0AN0_VHG5Y9MM"; }        # Slot 0
      { device = "/dev/disk/by-id/ata-WDC_WD101EFBX-68B0AN0_VHG5Y60M"; }        # Slot 1
      { device = "/dev/disk/by-id/ata-ST22000NM001E-3HM103_ZX29DRVW"; }         # Slot 2
      { device = "/dev/disk/by-id/ata-ST8000VN004-2M2101_WSD2EJM1"; }           # Slot 3
      { device = "/dev/disk/by-id/ata-ST8000VN004-2M2101_WSD2EHS6"; }           # Slot 4
      { device = "/dev/disk/by-id/ata-ST22000NT001-3LS101_ZX289H5Z"; }          # Slot 5
      { device = "/dev/disk/by-id/ata-ST22000NT001-3LS101_ZX289HFP"; }          # Slot 6
      { device = "/dev/disk/by-id/ata-ST22000NM001E-3HM103_ZX29DSG1"; }         # Slot 7
    ];
    notifications.mail = {
      enable    = true;
      mailer    = "${pkgs.system-sendmail}/bin/sendmail";
      recipient = builtins.elemAt notifyEmails 0; # FIXME: figure out how to send to multiple addresses.
      sender    = noreplyEmail;
    };
  };

  services.nullmailer.enable = true;
  services.nullmailer.config = {
    me            = "CADANCE";
    adminaddr     = lib.strings.concatStringsSep "," (notifyEmails);
    allmailfrom   = noreplyEmail;
    helohost      = "cadance.vs49688.net";
  };
  services.nullmailer.remotesFile = config.sops.secrets."nullmailer/remotes.conf".path;
  services.nullmailer.setSendmail = true;

  services.ntpd-rs = {
    enable = true;
    settings = {
      server = [ { listen = "0.0.0.0:123"; } ];
    };
  };

  networking.hostName = "CADANCE";
  networking.hostId   = "fe783969";
  networking.wireless.enable = false;

  networking.interfaces.enp42s0.useDHCP   = true;
  networking.usePredictableInterfaceNames = true;

  # Enable NAT'ting for containers
  networking.nat.enable = true;
  networking.nat.externalInterface = "enp42s0";

  networking.vlans.vlan101.id = 101;
  networking.vlans.vlan101.interface = "enp42s0";
  networking.interfaces.vlan101.useDHCP = true;

  networking.vlans.vlan102.id = 102;
  networking.vlans.vlan102.interface = "enp42s0";
  networking.interfaces.vlan102.useDHCP = true;

  networking.vlans.vlan103.id = 103;
  networking.vlans.vlan103.interface = "enp42s0";
  networking.interfaces.vlan103.useDHCP = true;

  networking.vlans.vlan64.id = 64;
  networking.vlans.vlan64.interface = "enp42s0";
  networking.interfaces.vlan64.useDHCP = true;

  networking.dhcpcd.extraConfig = ''
    interface vlan64
      metric 2000
    interface vlan101
      metric 2001
    interface vlan102
      metric 2002
    interface vlan103
      metric 2003
  '';

  networking.extraHosts = ''
    127.0.1.1 cadance.vs49688.net git.vs49688.net
  '';

  services.fail2ban.enable = true;
  services.fail2ban.bantime-increment.enable = true;
  services.fail2ban.bantime-increment.rndtime = "15m";
  services.fail2ban.ignoreIP = [
    "127.0.0.1/8"
  ] ++ config.cadance.settings.localNetworks;

  virtualisation.libvirtd.enable = false;
  virtualisation.oci-containers.backend = "docker";

  virtualisation.docker.package = pkgs.docker_29;
  virtualisation.docker.autoPrune = {
    enable = true;
    flags  = [ "--all" ];
    dates  = "daily";
  };

  environment.systemPackages = with pkgs; [
    openssl
    smartmontools
    git
    jq
    hdparm
    sqlite-interactive
    nix-prefetch-scripts
    tcpdump

    ncdu
    libva-utils

    jless
    jd-diff-patch
    yt-dlp
    ffmpeg-headless
  ];

  programs.gnupg.agent = {
    enable           = true;
    enableSSHSupport = false;
    pinentryPackage  = pkgs.pinentry-curses;
  };

  services.openssh = {
    settings.X11Forwarding = false;
    settings.PasswordAuthentication = true; # Paired with OTP

    hostKeys = [
      { path = "/data/root/ssh_host_ecdsa_key";   type = "ecdsa-sha2-nistp256"; }
      { path = "/data/root/ssh_host_ed25519_key"; type = "ed25519"; }
      { path = "/data/root/ssh_host_rsa_key";     type = "rsa"; }
    ];
  };

  security.pam.oath.usersFile = "/etc/nixos/users.oath";

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 22000 631 ];
  networking.firewall.allowedUDPPorts = [ 22000 631 123 ];

  services.avahi.enable = true;
  services.avahi.openFirewall = true;
  services.avahi.nssmdns4 = true;
  services.avahi.publish = {
    enable = true;
    userServices = true;
  };

  services.printing.enable = true;
  services.printing.browsing = true;
  services.printing.defaultShared = true;
  services.printing.drivers = [ pkgs.gutenprint ];

  services.printing.listenAddresses = [ "*:631" ];
  services.printing.allowFrom = [ "all" ];
  services.printing.extraConf = ''
    DefaultPaperSize A4
  '';

  hardware.sane.enable = false;

  cadance.vaultwarden = {
    enable = true;
    hostName = "vaultwarden.vs49688.net";
    environmentFile = config.sops.secrets."vaultwarden/env".path;

    smtpHost = lib.mkDefault "smtp.example.com";
    smtpFrom = lib.mkDefault "noreply@example.com";
    smtpFromName = lib.mkDefault "Vaultwarden";
    smtpUsername = lib.mkDefault "vaultwarden@example.com";
  };

  systemd.services.vaultwarden.serviceConfig.StateDirectoryMode = lib.mkForce "750";

  cadance.auth.enable = true;
  cadance.auth.localNetworks = config.cadance.settings.localNetworks;
  cadance.auth.lldap = {
    host = "id.vs49688.net";
    baseDN = lib.mkDefault "dc=example,dc=com";
    adminUserEmail = lib.mkDefault "admin@example.com";
    adminUserDN = lib.mkDefault "admin";
    jwtSecretFile = config.sops.secrets."lldap/jwt_secret".path;
    userPassFile = config.sops.secrets."lldap/user_pass".path;
    keyFile = config.sops.secrets."lldap/key_file".path;
  };

  cadance.auth.authelia = {
    host                      = "auth.vs49688.net";
    domain                    = "vs49688.net";
    ldapPasswordFile          = config.sops.secrets."authelia/ldap_password".path;
    jwtSecretFile             = config.sops.secrets."authelia/jwt_secret".path;
    storageEncryptionKeyFile  = config.sops.secrets."authelia/storage_encryption_key".path;
    sessionSecretFile         = config.sops.secrets."authelia/session_secret".path;
    oidcHmacSecretFile        = config.sops.secrets."authelia/oidc_hmac_secret".path;
    jwksKey                   = config.sops.secrets."authelia/oidc_jwks_key".path;
    smtpAddress               = lib.mkDefault "submissions://smtp.example.com:465";
    smtpUsername              = lib.mkDefault "noreply@example.com";
    smtpSender                = lib.mkDefault "Authelia <noreply@example.com>";
    smtpPasswordFile          = config.sops.secrets."authelia/smtp_password".path;
    clientsYml                = config.sops.secrets."authelia/clients.yml".path;
  };


  services.samba = {
    enable          = true;
    openFirewall    = true;
    nmbd.enable     = false;
    winbindd.enable = false;

    settings.global = {
      "workgroup" = "WORKGROUP";
      "server string" = "%h";
      "server role" = "standalone server";
      "obey pam restrictions" = "yes";
      "map to guest" = "bad user";
      "local master" = "no";
      "domain master" = "no";
      "preferred master" = "no";
      "security" = "user";
    };
  };

  services.xserver.enable = false;
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics.enable = true;

  users.mutableUsers = false;
  users.users.root.initialHashedPassword = defaultHashedPassword;
  users.users.root.hashedPasswordFile = "/data/passwords/root";

  systemd.services."notify-email@" = {
    path        = [ pkgs.cadance-mail ];
    description = "%i failure email notification";

    serviceConfig.User      = "root";
    serviceConfig.Type      = "oneshot";
    serviceConfig.ExecStart = "${pkgs.cadance-mail}/bin/mail.sh %i";
  };

  cadance.forgejo.enable = true;
  cadance.forgejo.appName = "The Vault";
  cadance.forgejo.hostName = "git.vs49688.net";
  cadance.forgejo.noreplyEmail = noreplyEmail;
  cadance.forgejo.smtpAddress = lib.mkDefault "smtp.example.com";
  cadance.forgejo.smtpUsername = lib.mkDefault "noreply@example.com";
  cadance.forgejo.smtpPasswordFile = config.sops.secrets."forgejo/mailpasswd".path;
  cadance.forgejo.runnerTokenFile = config.sops.secrets."forgejo/runner_env".path;
  cadance.forgejo.localNetworks = config.cadance.settings.localNetworks;

  cadance.backup = {
    enable   = true;
    startAt  = "*-*-* 02:00:00";
    resticTokenFile = config.sops.secrets."backup/restic_token".path;
    awsProfile = "default";
    awsSharedCredentialsFile = config.sops.secrets."backup/aws_shared_credentials_file".path;
    s3Bucket = lib.mkDefault "my-email-backups";

    offlineimap = {
      remoteHost = lib.mkDefault "imap.example.com";
      remoteUser = lib.mkDefault "backupuser@example.com";
      passwordFile = lib.mkDefault "/secrets/email-backup-password";
    };
  };

  services.syncthing = {
    enable    = true;

    user      = primaryUser.username;
    group     = primaryUser.username;

    configDir = "${primaryUser.home}/.config/syncthing";
    dataDir   = "/storage/SyncRoot";

    guiAddress = "127.0.0.1:8384";

    cert = config.sops.secrets."syncthing/cert.pem".path;
    key  = config.sops.secrets."syncthing/key.pem".path;

    overrideDevices = false;
    overrideFolders = false;

    openDefaultPorts = true;
  };

  services.nginx.enable = lib.mkForce false;

  services.caddy.enable = true;
  services.caddy.package = pkgs.caddy.withPlugins {
    plugins = [
      "github.com/WeidiDeng/caddy-cloudflare-ip@v0.0.0-20231130002422-f53b62aa13cb"
    ];

    hash = "sha256-+rp0vOGrJVoQ+F4yAyKuitnD0geUBmyuWPWrkbX+s+4=";
  };

  systemd.services.caddy.serviceConfig.RuntimeDirectoryPreserve = true;
  systemd.services.caddy.serviceConfig.RuntimeDirectory = "caddy";

  services.caddy.globalConfig = ''
    skip_install_trust

    servers {
      trusted_proxies cloudflare {
        interval 12h
        timeout 15s
      }
    }
  '';

  services.caddy.email = "webmaster@vs49688.net";
  services.caddy.acmeCA = "https://acme-v02.api.letsencrypt.org/directory";

  services.caddy.virtualHosts."http://192.168.64.5".extraConfig = ''
    file_server {
      root /var/www/cadance.vs49688.net/htdocs
    }
  '';

  services.caddy.virtualHosts."cadance.vs49688.net".extraConfig = ''
    ${caddyBlacklist}

    root * /var/www/cadance.vs49688.net/htdocs

    header {
      # disable FLoC tracking
      Permissions-Policy interest-cohort=()

      # Disable indexing and archiving
      X-Robots-Tag noindex,noarchive
    }

    handle_path /git {
        redir https://git.vs49688.net{uri} permanent
    }

    handle_path /git/* {
        redir https://git.vs49688.net{uri} permanent
    }

    handle_path /music {
        redir https://music.vs49688.net{uri} permanent
    }

    handle_path /music/* {
        redir https://music.vs49688.net{uri} permanent
    }

    @kodi {
      header_regexp kodi User-Agent ^Kodi
    }

    redir /musstore /musstore/
    handle_path /musstore/* {
      respond @blacklist 403

      encode zstd gzip

      file_server @kodi {
        root ${musicMountPath}/music
        browse ${./kodi.gohtml}
      }

      file_server {
        root ${musicMountPath}/music
        browse
      }
    }

    redir /sync /sync/
    handle_path /sync/* {
      forward_auth @blacklist unix//run/authelia/authelia.sock {
        uri /api/authz/forward-auth
      }

      reverse_proxy ${config.services.syncthing.guiAddress}
    }
  '';

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;

    ensureDatabases = [
      "docspell"
      "unifi"
    ];

    ensureUsers = [
      { name = "docspell"; ensureDBOwnership = true; }
      { name = "unifi"; ensureDBOwnership = true; }
    ];

    authentication = ''
      host docspell docspell ${containerAddresses.docspell.local}/32 trust
      host unifi    unifi    ${containerAddresses.unifi.local}/32    trust
    '';

    settings.listen_addresses = lib.mkForce "localhost,${containerAddresses.docspell.host},${containerAddresses.unifi.host}";
  };

  systemd.services.postgresql.serviceConfig.RuntimeDirectoryPreserve = true;

  services.caddy.virtualHosts."http://10.0.102.5".extraConfig = let
    hippie68 = pkgs.fetchFromGitHub {
      owner = "hippie68";
      repo = "hippie68.github.io";
      rev = "a85a7286cf029851a9993014926c4ff495d09cf2";
      hash = "sha256-64Hul5CDdIKjcQdHP2gwuzS+3agcxc55XFnCbmfKiHg=";
    };
  in ''
    file_server {
      root ${hippie68}
    }
  '';

  cadance.navidrome = {
    enable         = true;
    musicMountPath = musicMountPath;
    virtualHost    = "music.vs49688.net";

    environmentFile = config.sops.secrets."navidrome/env".path;
  };

  cadance.immich = {
    enable = true;

    hostName = "immich.vs49688.net";

    smtpFrom = lib.mkDefault "Immich <noreply@example.com>";
    smtpHost = lib.mkDefault "smtp.example.com";
    smtpUsername = lib.mkDefault "immich@example.com";
    smtpSecretFile = config.sops.secrets."immich/smtp_password".path;

    oauthClientId = lib.mkDefault "00000000-0000-0000-0000-000000000000";
    oauthIssuerUrl = "https://auth.vs49688.net/.well-known/openid-configuration";
    oauthClientSecretPath = config.sops.secrets."immich/oauth_client_secret".path;
    oauthButtonText = "Login with auth.vs49688.net";
  };

  cadance.nextcloud = {
    enable = true;
    hostName = "vs49688.net";
    adminpassFile = config.sops.secrets."nextcloud/adminpass".path;
    package = pkgs.nextcloud33;
  };


  cadance.docspell = {
    enable = true;

    hostAddress  = containerAddresses.docspell.host;
    localAddress = containerAddresses.docspell.local;

    virtualHost  = "docs.vs49688.net";

    restserverAppName = "Docspell";
    restserverAppId   = "cadance-rest-01";
    joexAppId         = "cadance-joex-01";

    oidcDisplayName    = "auth.vs49688.net";
    oidcClientId       = lib.mkDefault "00000000-0000-0000-0000-000000000000";
    oidcAutheliaServer = "auth.vs49688.net";

    jdbcUrl      = "jdbc:postgresql://${containerAddresses.docspell.host}:${toString config.services.postgresql.settings.port}/docspell";
    jdbcUser     = "docspell";
    jdbcPassword = "";

    adminTokenFile = config.sops.secrets."docspell/admin_token".path;
    oidcClientSecretFile = config.sops.secrets."docspell/oidc_client_secret".path;
  };
  networking.firewall.interfaces.ve-docspell.allowedTCPPorts = [ config.services.postgresql.settings.port ];
  systemd.services."container@docspell".after = [ "postgresql.target" ];

  services.caddy.virtualHosts."docs.vs49688.net".extraConfig = ''
    ${caddyBlacklist}

    forward_auth @blacklist unix//run/authelia/authelia.sock {
      uri /api/authz/forward-auth
    }
  '';

  cadance.containers.unifi = {
    enable = true;
    hostAddress = containerAddresses.unifi.host;
    localAddress = containerAddresses.unifi.local;
    managementInterface = "vlan64";
    virtualHost = "unifi.vs49688.net";
    dataDir = "/var/lib/unifi/data";
    unifiPackage = pkgs.unifi;
    mongodbPackage = pkgs.mongodb-ce;
    mongodbDataDir = "/var/db/mongodb-unifi";
  };
  networking.firewall.interfaces.ve-unifi.allowedTCPPorts = [ config.services.postgresql.settings.port ];

  services.caddy.virtualHosts."unifi.vs49688.net".extraConfig = ''
    ${caddyBlacklist}

    forward_auth @blacklist unix//run/authelia/authelia.sock {
      uri /api/authz/forward-auth
    }
  '';

  cadance.containers.torrent = {
    enable          = true;
    port            = 20075;
    parentInterface = "vlan101";
    hostAddress     = containerAddresses.torrent.host;
    localAddress    = containerAddresses.torrent.local;
    downloadDir     = "/downloads";
    stateDir        = "/var/lib/transmission";

    virtualHost = "cadance.vs49688.net";
    baseUrl     = "/transmission";

    extraCaddyConfig = ''
      forward_auth unix//run/authelia/authelia.sock {
        uri /api/authz/forward-auth
      }
    '';
  };

  services.audiobookshelf.enable = true;
  systemd.services.audiobookshelf = {
    confinement.enable = true;
    confinement.mode = "full-apivfs";
    confinement.configureNetworking = true;

    serviceConfig.BindPaths = [
      "${musicMountPath}/audiobooks"
      "${musicMountPath}/podcasts"
    ];
  };

  services.caddy.virtualHosts."shelf.vs49688.net".extraConfig = ''
    encode zstd gzip
    reverse_proxy http://${config.services.audiobookshelf.host}:${toString config.services.audiobookshelf.port}
  '';

  cadance.ai.enable = true;
  cadance.ai.hostName = "chat.vs49688.net";
  cadance.ai.enableOpenAIModels = true;
  cadance.ai.enableAnthropicModels = true;
  cadance.ai.enableXAIModels = true;
  cadance.ai.enableDeepSeekModels = true;
  cadance.ai.openWebUIEnvironmentFile = config.sops.secrets."open-webui/env".path;
  cadance.ai.litellmEnvironmentFile = config.sops.secrets."litellm/env".path;
  cadance.ai.oauthClientId = lib.mkDefault "00000000-0000-0000-0000-000000000000";
  cadance.ai.oauthProviderUrl = "https://auth.vs49688.net/.well-known/openid-configuration";
  cadance.ai.oauthProviderName = "auth.vs49688.net";

  services.caddy.virtualHosts."chat.vs49688.net".extraConfig = ''
    ${caddyBlacklist}

    forward_auth @blacklist unix//run/authelia/authelia.sock {
      uri /api/authz/forward-auth
    }
  '';

  # Using impermanence to persist /var/lib/private/* causes /var/lib/private
  # to have 0755, which systemd _really_ doesn't like.
  systemd.tmpfiles.rules = [
    "z /var/lib/private 0700 root root  - -"
  ];

  cadance.crypto.enable = true;

  environment.persistence."/data".enable = true;

  system.stateVersion = "19.09";
}