##
# For dev machines.
##
{ config, pkgs, lib, ... }:
{
  imports = [
    ../settings
  ];

  boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkDefault 1;

  networking.firewall.extraCommands = ''
    # Block JetBrains from doing its local license check
    iptables -A OUTPUT -p udp --match multiport --sports 6942:6992 -j REJECT

    # Block JetBrains license check, outgoing multicast
    iptables -A OUTPUT -p udp -d 224.0.0.0/4 --match multiport --dports 8976:8979 -j DROP
  '';

  virtualisation.spiceUSBRedirection.enable = true;

  virtualisation.podman.enable = true;
  virtualisation.podman.dockerSocket.enable = true;
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
  networking.firewall.interfaces.podman0.allowedTCPPorts = [ 53 ];
  networking.firewall.interfaces.podman0.allowedUDPPorts = [ 53 ];
  networking.firewall.interfaces.podman1.allowedTCPPorts = [ 53 ];
  networking.firewall.interfaces.podman1.allowedUDPPorts = [ 53 ];

  programs.wireshark.enable  = lib.mkDefault true;
  programs.wireshark.package = pkgs.wireshark;

  programs.adb.enable = true;

  programs.java.enable  = true;
  programs.java.package = pkgs.openjdk17;

  programs.cdemu.enable = lib.mkDefault true;

  environment.systemPackages = let
    myPy = (pkgs.python3.withPackages (pi: with pi; [
      pip
      virtualenv

      dnspython
      grpcio-tools
      jinja2
      beautifulsoup4
      html5lib

      skyfield
      setuptools
    ]));
  in (with pkgs; [
      myPy
      (pipenv.override { python3 = myPy; })

      # Sysadmin
      ansible
      opentofu

      # IDEs
      vscodium
      notepadqq

      # Compilers/Assemblers
      mingw-w64-cc
      mingw32-cc
      uasm

      # Kubernetes/Container Stuff
      minikube
      kubectl
      kind
      kubernetes-helm
      k9s
      docker-compose
      docker # Just the client, we talk to podman

      # CLI Tools
      ninja
      nix-prefetch-git
      maven
      rustup
      pev
      # rappel
      bat
      dos2unix
      qpdf
      # hugo
      qrencode
      graphviz
      unifi-backup-decrypt

      unshield
      libgig

      # Misc
      kdiff3
      sqlitebrowser
      vgmstream
      drawio

      texlive.combined.scheme-full

      jetbrains.clion
      jetbrains.idea-ultimate
      jetbrains.pycharm-professional
      jetbrains.goland
      jetbrains.ruby-mine
      jetbrains.webstorm
  ]) ++ (lib.optionals pkgs.hostPlatform.isx86_64 (with pkgs; [
    # jetbrains.rider

    wimlib
    ghidra

    renderdoc
  ])) ++ (with pkgs; let
    goPackage = go_1_24;
    buildGoModule = buildGo124Module;
  in [
    goPackage
    (mockgen.override  { inherit buildGoModule; })
    (errcheck.override { inherit buildGoModule; })
    (go-tools.override { inherit buildGoModule; })
    (gotools.override  { inherit buildGoModule; })
    (gosec.override    { inherit buildGoModule; })
    (gocyclo.override  { inherit buildGoModule; })
    (revive.override   { inherit buildGoModule; })
    (govulncheck.override { /* inherit buildGoModule; */ })
    (gops.override { inherit buildGoModule; })
    (delve.override { inherit buildGoModule; })
  ]);

  programs.git.enable = true;
  programs.git.lfs.enable = true;

  hardware.graphics.extraPackages = with pkgs; [
    vulkan-validation-layers
  ];

  services.squid = {
    enable = true;
    extraConfig = ''
      dns_nameservers 1.1.1.1

      # This is sooooo fucking annoying.
      shutdown_lifetime 0

      acl vm_whitelist dstdom_regex '${./squid-whitelist.txt}'
      http_access allow vm_whitelist

      http_access deny all

      # Disable caching, we're a proxy only.
      cache deny all
    '';
  };

  users.users.${config.settings.primaryUser.username} = {
    extraGroups =
      lib.optionals config.programs.wireshark.enable [ "wireshark" ] ++
      lib.optionals config.programs.cdemu.enable [ config.programs.cdemu.group ] ++
      lib.optionals config.virtualisation.podman.enable [ "podman" ] ++
      lib.optionals config.programs.adb.enable [ "adbusers" ]
    ;

    packages = with pkgs; [
      crocutils
      zane-scripts.gocheck
    ];
  };
}
