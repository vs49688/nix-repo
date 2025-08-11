##
# TWILYSPARKLE
# Model: Dell XPS 15 9550
##
{ config, lib, pkgs, utils, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/gui6.nix
  ];

  nix.settings.system-features = [
    "nixos-test"
    "benchmark"
    "big-parallel"
    "kvm"
    "gccarch-skylake"
    "gcctune-skylake"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    "mitigations=off"
    "i915.enable_guc=3"
  ];

  boot.initrd.postResumeCommands = lib.mkAfter ''
    zfs rollback -r tank/private/root@blank
  '';

  boot.zfs.package = pkgs.zfs;
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  security.tpm2.enable = true;
  security.tpm2.pkcs11.enable = true;
  security.tpm2.tctiEnvironment.enable = true;

  hardware.bluetooth.enable = true;

  hardware.sane.enable = true;
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  programs.kdeconnect.enable = true;

  services.hardware.bolt.enable = true;

  networking.hostName = "TWILYSPARKLE";
  networking.hostId   = "aadd4376";

  networking.extraHosts = ''
    127.0.1.1 twilysparkle.vs49688.net
  '';

  fileSystems."/" = {
    options       = [ "noatime" "nodiratime" "xattr" "posixacl" ];
  };

  fileSystems."/nix" = {
    neededForBoot = true;
    options       = [ "noatime" "nodiratime" "discard" "xattr" "posixacl" ];
  };

  fileSystems."/data" = {
    neededForBoot = true;
    options       = [ "noatime" "nodiratime" "discard" "xattr" "posixacl" ];
  };

  boot.zfs.requestEncryptionCredentials = [ "tank/private" ];
  boot.zfs.forceImportAll = true; # Only adds the -f flag to "zpool import", doesn't import ALL pools.

  users.mutableUsers = false;
  users.users.root.hashedPasswordFile = "/data/passwords/root";

  users.users.${config.settings.primaryUser.username} = {
    hashedPasswordFile = "/data/passwords/${config.settings.primaryUser.username}";

    extraGroups = [ "tss" ];
  };

  i18n.supportedLocales = [
    "C.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
    "${config.i18n.defaultLocale}/UTF-8"
    "ru_RU.UTF-8/UTF-8"
  ];

  services.thermald.enable = true;

  system.stateVersion = "22.05";

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
      { directory = "/etc/NetworkManager/system-connections"; mode = "0700"; }
      {
        directory = config.settings.primaryUser.home;
        user = config.settings.primaryUser.username;
        group = config.settings.primaryUser.username;
        mode = "0700";
      }
    ];

    files = [
      "/etc/machine-id"
    ];
  };
}
