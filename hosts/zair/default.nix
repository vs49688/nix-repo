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

  hardware.asahi.enable = true;

  # NB: set privately, can't redistribute.
  hardware.asahi.extractPeripheralFirmware = lib.mkDefault false;

  # Remove one https://github.com/tpwrules/nixos-apple-silicon/pull/158 is merged.
  # using an IO scheduler is pretty pointless on NVME devices as fast as Apple's
  # disable the IO scheduler on NVME to conserve CPU cycles
  # sources:
  # https://wiki.ubuntu.com/Kernel/Reference/IOSchedulers
  # https://www.phoronix.com/review/linux-56-nvme/4
  #
  # NB: This is done in the fork.
  # services.udev.extraRules = ''
  #   ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
  # '';

  users.users.${config.settings.primaryUser.username} = {
    packages = with pkgs; [
      luanti
      (croc-lotg.override { version = "1.5.7"; allowSubstitutes = true; })
    ];
  };

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

  networking.hostName = "ZAIR";
  networking.hostId   = "faaf43fa";

  networking.firewall = let
    torrentPort = 62092;
  in {
    interfaces.airvpn.allowedTCPPorts = [ torrentPort 8080 ];
    interfaces.airvpn.allowedUDPPorts = [ torrentPort ];
  };

  networking.extraHosts = ''
    127.0.1.1 zair.vs49688.net
  '';

  fileSystems."/" = {
    options       = [ "noatime" "nodiratime" "discard" ];
  };

  # THIS IS THE UUID OF THE LUKS PARTITION, /dev/vda2
  boot.initrd.luks.devices.root = {
    device = "/dev/disk/by-uuid/534a9c69-4012-492f-83a8-f3a0eb7e0fdf";
    preLVM = true;
    allowDiscards = true;
  };


  i18n.supportedLocales = [
    "C.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
    "${config.i18n.defaultLocale}/UTF-8"
    "ru_RU.UTF-8/UTF-8"
  ];

  systemd.tmpfiles.rules = [
    "L /usr/lib/locale/locale-archive - - - - /run/current-system/sw/lib/locale/locale-archive"
  ];

  services.syncthing.enable  = true;

  system.stateVersion = "23.05";
}
