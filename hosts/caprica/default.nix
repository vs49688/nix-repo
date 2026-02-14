{ config, pkgs, lib, ... }:
let
  notifyEmail = "zane@zanevaniperen.com";
  noreplyEmail = "noreply@cadance.vs49688.net";
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/gui6.nix
    ../../modules/devmachine
    #../../modules/old/caprica-vfio
  ];

  nix.settings.system-features = [
    "nixos-test"
    "benchmark"
    "big-parallel"
    "kvm"
    "gccarch-znver1"
    "gcctune-znver1"
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 1;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    "mitigations=off"
  ];

  boot.blacklistedKernelModules = [ "alx" ];

  boot.zfs.package = pkgs.zfs_2_4;
  boot.kernelPackages = pkgs.linuxPackages_6_18;

  networking.hostName = "CAPRICA";
  networking.hostId   = "100b9bbe";

  networking.firewall = let
    sambaTCPPorts = [ 139 445 ];
    sambaUDPPorts = [ 137 138 445 ];

    torrentPort = 47944;
  in {
    interfaces.enp5s0.allowedTCPPorts = sambaTCPPorts ++ [
      # Minecrafft
      25565
      # WoW Realmd
      3724
      # WoW Mangosd
      8085
      # For Dev Web Servers
      8080
      # Torrenting
      torrentPort
    ];

    interfaces.enp5s0.allowedUDPPorts = sambaUDPPorts ++ [
      torrentPort
    ];

    interfaces.airvpn.allowedTCPPorts = [ torrentPort ];
    interfaces.airvpn.allowedUDPPorts = [ torrentPort ];

    interfaces.virbr0.allowedTCPPorts = sambaTCPPorts;
    interfaces.virbr0.allowedUDPPorts = sambaUDPPorts;

    interfaces."enp5s0.5".allowedTCPPorts = sambaTCPPorts;
    interfaces."enp5s0.5".allowedUDPPorts = sambaTCPPorts;
  };

  networking.extraHosts = ''
    127.0.1.1   caprica.vs49688.net
  '';

  fileSystems."/" = {
    options       = [ "noatime" "nodiratime" ];
  };

  fileSystems."/nix" = {
    neededForBoot = true;
    options       = [ "noatime" "nodiratime" ];
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

  services.smartd = {
    enable = true;

    devices = [
      ##
      # Root
      ##
      { device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S4EWNF0M319804Z"; }
    ];

    notifications.mail = {
      enable    = true;
      mailer    = "${pkgs.system-sendmail}/bin/sendmail";
      recipient = notifyEmail;
      sender    = noreplyEmail;
    };
  };

  hardware.bluetooth.enable = true;

  services.printing.enable = true;

  services.avahi.enable = true;

  services.prometheus.exporters.node.enable = true;
  services.prometheus.exporters.node.openFirewall = true;
  services.prometheus.exporters.smartctl.enable = true;
  services.prometheus.exporters.smartctl.openFirewall = true;

  services.nullmailer.enable = true;
  services.nullmailer.config = {
    me          = "CAPRICA";
    adminaddr   = notifyEmail;
    allmailfrom = noreplyEmail;
    helohost    = "caprica.vs49688.net";
  };
  services.nullmailer.remotesFile = "/etc/nixos/remotes.nullmailer.conf";
  services.nullmailer.setSendmail = true;

  # Development database
  services.postgresql.enable = true;

  users.mutableUsers = false;
  users.users.root.hashedPasswordFile = "/data/passwords/root";

  users.users.${config.settings.primaryUser.username} = {
    hashedPasswordFile = "/data/passwords/${config.settings.primaryUser.username}";
    packages = with pkgs; [
      luanti
      mgba
      mednafen
      mednaffe
      rpcs3
      pcsx2
      jpsxdec

      zane-scripts.startgame

      solar2
      supermeatboy
      (croc-lotg.override { version = "1.5.7"; allowSubstitutes = true; })
      # xash3d-fwgs-full
    ];
  };

  programs.steam.enable = true;

  boot.initrd.kernelModules     = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.graphics.extraPackages = with pkgs; [
    #rocm-opencl-icd
    #rocm-opencl-runtime
  ];

  boot.initrd.postResumeCommands = lib.mkAfter ''
    zfs rollback -r caprica/private/root@empty
  '';

  services.samba   = {
    enable          = true;
    nmbd.enable     = true;
    winbindd.enable = true;
    securityType    = "user";

    settings.global = {
      "workgroup" = "WORKGROUP";
      "server string" = "%h";
      "server role" = "standalone server";
      "obey pam restrictions" = "yes";
      "map to guest" = "bad user";
      "local master" = "no";
      "domain master" = "no";
      "preferred master" = "no";
      "log level" = "3 passdb:5 auth:5";
      security = "user";
    };
  };

  services.syncthing.enable  = true;

  powerManagement.cpuFreqGovernor = "performance";

  system.stateVersion = "22.05";

  fileSystems."/data" = {
    neededForBoot = true;
    options       = [ "noatime" "nodiratime" "xattr" "posixacl" ];
  };

  fileSystems."/games" = {
    options = [ "noatime" "nodiratime" "xattr" "posixacl" ];
  };

  boot.zfs.requestEncryptionCredentials = [ "caprica/private" ];
  boot.zfs.forceImportAll = true; # Only adds the -f flag to "zpool import", doesn't import ALL pools.

  services.openssh.hostKeys = [
    {
      path = "/data/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
    {
      path = "/data/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }
  ];

  environment.persistence."/data" = {
    hideMounts = true;

    directories = [
      { directory = "/var/log";                               mode = "0755"; }
      { directory = "/var/lib/nixos";                         mode = "0755"; }
      { directory = "/var/lib/bluetooth";                     mode = "0700"; }
      { directory = "/var/lib/libvirt";                       mode = "0755"; }
      { directory = "/var/lib/containers";                    mode = "0700"; }
      { directory = "/var/lib/samba";                         mode = "0755"; }
      { directory = "/var/lib/postgresql";                    mode = "0750"; }
      { directory = "/etc/NetworkManager/system-connections"; mode = "0700"; }
      { directory = "/home/zane"; user = "zane"; group = "zane"; mode = "0700"; }
    ];

    files = [
      "/etc/machine-id"
    ];
  };
}
