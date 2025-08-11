##
# MORNINGSTAR
# Model: Lenovo P14s Gen 4 AMD
##
{ config, lib, pkgs, utils, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/gui6.nix
    ../../modules/devmachine
  ];

  nix.settings.system-features = [
    "nixos-test"
    "benchmark"
    "big-parallel"
    "kvm"
    "gccarch-znver4"
    "gcctune-znver4"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    "mitigations=off"
  ];

  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.initrd.postResumeCommands = lib.mkAfter ''
    zfs rollback -r morningstar/private/root@empty
  '';

  boot.zfs.package = pkgs.zfs;
  boot.kernelPackages = pkgs.linuxPackages_6_15;

  security.tpm2.enable = true;
  security.tpm2.pkcs11.enable = true;
  security.tpm2.tctiEnvironment.enable = true;

  programs.cdemu.enable = true;

  services.acpid = {
    enable = true;
    # logEvents = true;

    handlers.syncthing = lib.mkIf config.services.syncthing.enable {
      event = "ac_adapter.*";
      action = ''
        vals=($1)
        case ''${vals[3]} in
            00000000)
                ${pkgs.systemd}/bin/systemctl stop syncthing
                ;;
            00000001)
                ${pkgs.systemd}/bin/systemctl start syncthing
                ;;
        esac
      '';
    };
  };

  hardware.bluetooth.enable = true;

  hardware.sane.enable = true;
  hardware.sane.extraBackends = [
    pkgs.utsushi
    pkgs.epsonscan2
  ];
  services.udev.packages = [
    pkgs.utsushi
    pkgs.epsonscan2
  ];

  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  programs.kdeconnect.enable = true;

  services.hardware.bolt.enable = true;

  networking.hostName = "MORNINGSTAR";
  networking.hostId   = "ac94b74f";

  networking.firewall.allowedTCPPorts = [ 80 443 8080 ];

  networking.modemmanager.enable = true;

  networking.extraHosts = ''
    127.0.1.1 morningstar.vs49688.net
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

  boot.zfs.requestEncryptionCredentials = [ "morningstar/private" ];
  boot.zfs.forceImportAll = true; # Only adds the -f flag to "zpool import", doesn't import ALL pools.

  users.mutableUsers = false;
  users.users.root.hashedPasswordFile = "/data/passwords/root";

  users.users.${config.settings.primaryUser.username} = {
    hashedPasswordFile = "/data/passwords/${config.settings.primaryUser.username}";
    packages = with pkgs; [
      minetest
      # anki
      solar2
      supermeatboy
      croc-lotg
      xash3d-fwgs-full
    ];

    extraGroups = [ "tss" ];
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

  programs.quark-goldleaf.enable = true;

  programs.steam.enable = true;

  services.syncthing.enable  = true;

  services.pipewire.wireplumber.extraConfig."10-disable-camera" = {
    "wireplumber.profiles" = {
      main = {
        "monitor.libcamera" = "disabled";
      };
    };
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

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

  services.postgresql.enable = true;
  services.minio.enable = true;

  systemd.services.set-battery-threshold = {
    description = "set battery charge threshold";

    confinement.enable = true;
    confinement.mode = "full-apivfs";
    confinement.binSh = null;

    after = [ "multi-user.target" ];

    unitConfig.ConditionPathExists = "/sys/class/power_supply/BAT0/charge_control_end_threshold";

    serviceConfig.ExecStart = let
      args = [
        "-c"
        "echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold"
      ];
    in ''
      ${pkgs.bash}/bin/sh ${utils.escapeSystemdExecArgs args}
    '';

    serviceConfig.Type = "oneshot";
    serviceConfig.User = "root";
    serviceConfig.Group = "root";
    serviceConfig.RemainAfterExit = true;
    serviceConfig.BindPaths = [ "/sys/class/power_supply/BAT0" ];
  };

  environment.systemPackages = with pkgs; [
    gzdoom
    scummvm
    modem-manager-gui
  ];

  # virtualisation.waydroid.enable = true;

  environment.persistence."/data" = {
    hideMounts = true;

    directories = [
      { directory = "/var/log";                               mode = "0755"; }
      { directory = "/var/lib/nixos";                         mode = "0755"; }
      { directory = "/var/lib/bluetooth";                     mode = "0700"; }
      { directory = "/var/lib/libvirt";                       mode = "0755"; }
      { directory = "/var/lib/containers";                    mode = "0700"; }
      { directory = "/var/lib/postgresql";                    mode = "0750"; }
      { directory = "/var/lib/minio";                         mode = "0750"; }
      { directory = "/var/lib/waydroid";                      mode = "0755"; }
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
