{ config, pkgs, lib, ... }:
let
  channelBase = "/etc/nixpkgs/channels";
  nixpkgsPath = "${channelBase}/nixpkgs";
in {

  options.nix.useCadance = lib.mkOption {
    type        = lib.types.bool;
    description = "add CADANCE as a substituter";
    default     = true;
  };

  config = {
    ##
    # GC everything older than 7 days
    ##
    nix.gc.automatic  = lib.mkDefault true;
    nix.gc.options    = lib.mkDefault "--delete-older-than 7d";
    nix.gc.persistent = lib.mkDefault true;
    nix.settings.auto-optimise-store = lib.mkDefault true;

    ##
    # Use CADANCE as a substituter
    ##
    nix.settings.substituters = lib.mkIf config.nix.useCadance [
      "https://cadance.vs49688.net/cache"
    ];

    nix.settings.trusted-public-keys = lib.mkIf config.nix.useCadance [
      "cadance.vs49688,net-1:EQcyD9wxzTEdAuqCHbRZUx09b++wE7eA7VZ+7M55npU="
    ];

    ##
    # Enable nix and flakes
    ##
    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';

    ##
    # Force the "nixpkgs" channel to the current nixpkgs.
    ##
    nix.nixPath = [
      "nixpkgs=${nixpkgsPath}"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];

    systemd.tmpfiles.rules = [
      "L+ ${nixpkgsPath}     - - - - ${pkgs.path}"
    ];
  };
}