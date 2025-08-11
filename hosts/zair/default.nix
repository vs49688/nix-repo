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

  hardware.asahi.useExperimentalGPUDriver = true;

  system.autoUpgrade.flags = [ "--impure" ];

  environment.systemPackages = with pkgs; [
    asahi-bless
  ];

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
      minetest
    ];
  };

  # Needs to be built with --impure for this.
  hardware.asahi.experimentalGPUInstallMode = "replace";

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
    "ja_JP.UTF-8/UTF-8"
  ];

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5.waylandFrontend = true;

    fcitx5.addons = with pkgs; [
      fcitx5-mozc
    ];
  };

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

  system.stateVersion = "23.05";
}
