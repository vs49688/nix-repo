{ config, pkgs, lib, ... }:
{
  imports = [
    ./nix.nix
    ./systemd-confinement-networking.nix
    ./systemd-confinement-sendmail.nix

    # Work around https://github.com/NixOS/nixpkgs/issues/170573
    ({ config, lib, ... }: {
      config = lib.mkIf config.hardware.bluetooth.enable {
        systemd.tmpfiles.rules = [
          "d /var/lib/bluetooth 700 root root - -"
        ];
        systemd.targets."bluetooth".after = ["systemd-tmpfiles-setup.service"];
      };
    })
  ];

  nixpkgs.config.allowUnfree = lib.mkDefault true;

  boot.tmp.cleanOnBoot = lib.mkDefault true;

  # https://github.com/NixOS/nixpkgs/issues/41426
  # https://github.com/NixOS/nixpkgs/issues/96255
  # https://github.com/NixOS/nixpkgs/issues/160599
  environment.sessionVariables.NIX_PROFILES = "${lib.concatStringsSep " " (lib.reverseList config.environment.profiles)}";

  services.logind.killUserProcesses = true;

  services.fstrim.enable = lib.mkDefault true;
  services.fwupd.enable = lib.mkDefault true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = lib.mkDefault false;

  security.sudo.wheelNeedsPassword = lib.mkDefault true;
  security.apparmor.enable = lib.mkDefault true;

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault pkgs.hostPlatform.isx86_64;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault pkgs.hostPlatform.isx86_64;

  # Remove once this is fixed: https://github.com/NixOS/nixpkgs/pull/337289
  hardware.nvidia.open = lib.mkDefault false;

  i18n.defaultLocale = lib.mkDefault "en_AU.UTF-8";
  console.keyMap = lib.mkDefault "us";

  time.timeZone = lib.mkDefault "Australia/Brisbane";

  programs.htop.enable = lib.mkDefault true;
  programs.iftop.enable = lib.mkDefault true;
  programs.iotop.enable = lib.mkDefault true;
  programs.tmux.enable = lib.mkDefault true;

  programs.neovim = {
    enable = true;

    configure.customRC = ''
      set tabstop=4
      set shiftwidth=4
      set expandtab
      set mouse=

      syntax on
    '';

    withNodeJs  = false;
    withPython3 = false;
    withRuby    = false;
    viAlias     = true;
    vimAlias    = true;
  };

  environment.systemPackages = with pkgs; [
    wget
    parted
    gnupg
    pv
    lsof
    file
    units
    bc
    dmidecode
    pciutils
    usbutils
    nethogs
    dnsutils
    sysstat
  ];
}
