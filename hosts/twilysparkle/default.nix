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

  boot.zfs.package = pkgs.zfs_2_4;
  boot.kernelPackages = pkgs.linuxPackages_6_18;

  security.tpm2.enable = true;
  security.tpm2.pkcs11.enable = true;
  security.tpm2.tctiEnvironment.enable = true;

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  hardware.nvidia.primeBatterySaverSpecialisation = true;

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
    options       = [ "defaults" "size=25%" "mode=755" ];
  };

  fileSystems."/nix" = {
    neededForBoot = true;
    options       = [ "noatime" "nodiratime" "xattr" "posixacl" ];
  };

  fileSystems."/data" = {
    neededForBoot = true;
    options       = [ "noatime" "nodiratime" "xattr" "posixacl" ];
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
    enable = true;
  };
}
