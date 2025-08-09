{ config, pkgs, lib, ... }:
let
  # Always change this after login. Crack this if you must, I don't care.
  defaultHashedPassword = "$6$BxuSRej5CnpDNrpD$WOFbzquMrmz4ulhVr6THPKID4HK1jwcv5DAtw5P4It8ZmfvwaCUIV2koEKwyattH2hyhHLqwGLO.HoLGNxzbJ.";
in
{
  imports = [
    ./base
	./settings
  ];

  ##
  # Enable all SysRq keys. I'd like to have this at 246, but
  # there's no flag to explicitly allow SysRq+v
  ##
  boot.kernel.sysctl."kernel.sysrq" = lib.mkDefault 1;

  boot.supportedFilesystems = [ "ntfs" "exfat" ];

  boot.extraModprobeConfig = ''
    options zfs zfs_dmu_offset_next_sync=0
  '';

  boot.kernelParams = let
    # echo '0bc2:231a:u,0bc2:2312:u,0bc2:3312:u,0bc2:3320:u' > /sys/module/usb_storage/parameters/quirks
    quirks = lib.concatStringsSep "," [
      # Disable UAS on Seagate enclosures.
      "0bc2:231a:u"
      "0bc2:2312:u"
      "0bc2:3312:u"
      "0bc2:3320:u"
    ];
  in [
    "usb_storage.quirks=${quirks}"
  ];

  environment.systemPackages = with pkgs; [
    # System Utils
    firejail killall
    fakeroot man-pages pax-utils
    parallel valgrind
    traceroute unzip p7zip openssl
    zip
    mtr sshfs ncdu

    edid-decode

    ##
    # C/C++/Native
    # Technically dev tools, but I feel safer if I have these
    ##
    binutils gitFull gnumake cmake pkg-config nasm
    (if pkgs.hostPlatform.isx86_64 then gcc_multi else gcc)
    gdb

    ##
    # These are just handy to have in general
    ##
    jq jless yq sqlite-interactive

    lm_sensors powertop

    ripgrep

    home-manager
  ] ++ lib.optionals config.virtualisation.libvirtd.enable [
    virtiofsd
  ];

  virtualisation.libvirtd.enable = lib.mkDefault true;

  programs.gnupg.agent = {
    enable           = true;
    enableSSHSupport = false;
  };

  programs.firejail.enable = true;

  services.openssh = {
    enable                          = true;
    ports                           = [ 22 ];
    openFirewall                    = true;

    settings.X11Forwarding = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = lib.mkDefault false;
    settings.KbdInteractiveAuthentication = lib.mkDefault false;
  };

  networking.firewall.enable          = lib.mkDefault true;
  networking.firewall.allowPing       = true;
  networking.wireguard.enable         = lib.mkDefault true;
  networking.firewall.trustedInterfaces = lib.optionals config.networking.firewall.enable [ "virbr0" "virbr1" ];

  networking.networkmanager.unmanaged = [
    "lo"
    "virbr0"
    "virbr1"
  ];

  # See https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577
  networking.firewall.checkReversePath = "loose";
  networking.firewall.allowedUDPPorts = lib.optionals config.networking.wireguard.enable [ 51820 ];

  networking.firewall.logRefusedPackets      = lib.mkDefault false;
  networking.firewall.logRefusedUnicastsOnly = lib.mkDefault true;

  users.mutableUsers = lib.mkDefault true;

  users.users.root.initialHashedPassword = defaultHashedPassword;

  users.groups.ssl.gid = 996;
  users.users.ssl = {
    isSystemUser = true;
    group        = "ssl";
    uid          = 996;
  };

  users.groups.${config.settings.primaryUser.username} = {
    gid = 1000;
  };

  users.users.${config.settings.primaryUser.username} = {
    description    = config.settings.primaryUser.fullName;
    isNormalUser   = true;
    home           = config.settings.primaryUser.home;
    uid            = 1000;
    group          = config.settings.primaryUser.username;
    extraGroups    = [ "wheel" ] ++
    lib.optionals config.virtualisation.libvirtd.enable   ["libvirtd"] ++
    lib.optionals config.networking.networkmanager.enable ["networkmanager"] ++
    lib.optionals config.hardware.sane.enable             ["scanner" "lp"]
  ;

    initialHashedPassword = defaultHashedPassword;

    openssh.authorizedKeys.keys = config.settings.primaryUser.authorizedKeys;
  };

  services.syncthing = {
    package    = pkgs.syncthing;
    user       = config.settings.primaryUser.username;
    group      = config.settings.primaryUser.username;
    configDir  = "${config.settings.primaryUser.home}/.config/syncthing";
    dataDir    = lib.mkDefault config.settings.home;
    guiAddress = "127.0.0.1:8384";

    overrideDevices  = false;
    overrideFolders  = false;
    openDefaultPorts = true;
  };
}