{ config, pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.supportedFilesystems = [ "zfs" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "AVALON";
  networking.hostId   = "6661afde";

  networking.extraHosts = ''
    127.0.1.1 avalon.vs49688.net
  '';

  fileSystems."/" = {
    options       = [ "noatime" "nodiratime" "discard" ];
  };

  fileSystems."/media/OldData" = {
    neededForBoot = false;
    options       = [ "nofail" "noatime" "nodiratime" "xattr" "posixacl" ];
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

  services.xserver.videoDrivers = [
    ##
    # Use proprietary driver for, but NB:
    # There's a bug with Xorg and Nvidia in which using the
    # XPresent causes segfaults. I've configured the WMs
    # to use GLX instead, but be careful.
    ##
    "nvidia"
  ];

  hardware.nvidia.modesetting.enable = true;

  services.fail2ban.enable = true;
  services.fail2ban.ignoreIP = [
    "192.168.0.0/22"
  ];

  environment.systemPackages = with pkgs; [
    gzdoom
    scummvm

    sweethome3d.application
    sweethome3d.furniture-editor
    sweethome3d.textures-editor
  ];

  services.smartd = {
    enable = true;

    devices = [
      ##
      # Root
      ##
      { device = "/dev/disk/by-id/ata-KINGSTON_SUV400S37120G_50026B776504C496"; }

      ##
      # OldData
      ##
      { device = "/dev/disk/by-id/ata-WDC_WD10EZEX-00MFCA0_WD-WCC6Y2DFL54K"; }
      { device = "/dev/disk/by-id/ata-WDC_WD10EZEX-00MFCA0_WD-WCC6Y3RS619P"; }
    ];
  };

  services.printing.enable = true;

  services.avahi.enable = true;

  services.prometheus.exporters.node.enable = true;
  services.prometheus.exporters.node.openFirewall = true;

  networking.firewall.allowedTCPPorts = [
    # Samba
    139 445
  ];

  networking.firewall.allowedUDPPorts = [
    # Samba
    137 138 445
  ];


  services.samba   = {
    enable         = true;

    nmbd.enable = true;
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

  services.syncthing.enable = true;

  system.stateVersion = "22.05";
}

