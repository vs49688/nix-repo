{ config, pkgs, lib, utils, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/gui6.nix
    ../../modules/devmachine
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # NB: set privately, can't redistribute.
  hardware.asahi.extractPeripheralFirmware = lib.mkDefault false;

  environment.systemPackages = with pkgs; [
    asahi-bless
  ];

  boot.kernelParams = [
    "apple_dcp.show_notch=1"
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

  systemd.tmpfiles.rules = [
    "L /usr/lib/locale/locale-archive - - - - /run/current-system/sw/lib/locale/locale-archive"
  ];

  systemd.services.set-battery-threshold = {
    description = "set battery charge threshold";

    confinement.enable = true;
    confinement.mode = "full-apivfs";
    confinement.binSh = null;

    after = [ "multi-user.target" ];

    unitConfig.ConditionPathExists = "/sys/class/power_supply/macsmc-battery/charge_control_end_threshold";

    serviceConfig.ExecStart = let
      args = [
        "-c"
        "echo 80 > /sys/class/power_supply/macsmc-battery/charge_control_end_threshold"
      ];
    in ''
      ${pkgs.bash}/bin/sh ${utils.escapeSystemdExecArgs args}
    '';

    serviceConfig.Type = "oneshot";
    serviceConfig.User = "root";
    serviceConfig.Group = "root";
    serviceConfig.RemainAfterExit = true;
    serviceConfig.BindPaths = [ "/sys/class/power_supply/macsmc-battery" ];
  };

  system.stateVersion = "25.05";
}
