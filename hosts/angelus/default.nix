{ config, pkgs, lib, utils, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/asahi.nix
    ../../modules/gui6.nix
    ../../modules/devmachine
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # NB: set privately, can't redistribute.
  hardware.asahi.extractPeripheralFirmware = lib.mkDefault false;

  boot.kernelParams = [
    "appledrm.show_notch=1"
  ];

  hardware.graphics.enable32Bit = false;
  services.xserver.dpi = 192;
  hardware.cpu.intel.updateMicrocode = false;
  hardware.cpu.amd.updateMicrocode = false;

  hardware.bluetooth.enable = true;

  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  services.hardware.bolt.enable = true;

  # Conflicts hard with the built-in Asahi stuff.
  home-manager.users.${config.settings.primaryUser.username}.services.easyeffects.enable = false;

  networking.hostName = "ANGELUS";
  networking.hostId   = "a5cd7f5d";

  networking.extraHosts = ''
    127.0.1.1 angelus.vs49688.net
  '';

  fileSystems."/" = {
    options       = [ "noatime" "nodiratime" "discard" ];
  };

  # THIS IS THE UUID OF THE LUKS PARTITION, /dev/vda2
  boot.initrd.luks.devices.root = {
    device = "/dev/disk/by-uuid/6afaacc2-ecae-41f4-bab7-186e8c0506b4";
    preLVM = true;
    allowDiscards = true;
  };


  i18n.supportedLocales = [
    "C.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
    "${config.i18n.defaultLocale}/UTF-8"
    "ru_RU.UTF-8/UTF-8"
  ];

  users.users.${config.settings.primaryUser.username} = {
    packages = with pkgs; [
      (croc-lotg.override { version = "1.5.7"; allowSubstitutes = true; })
    ];
  };

  systemd.tmpfiles.rules = [
    "L /usr/lib/locale/locale-archive - - - - /run/current-system/sw/lib/locale/locale-archive"
  ];

  system.stateVersion = "25.05";
}
