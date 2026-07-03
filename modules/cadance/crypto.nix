{ lib, config, ... }: let
  cfg = config.cadance.crypto;
in {
  options.cadance.crypto = with lib; {
    enable = mkEnableOption "Enable Crypto";
  };

  config = lib.mkIf cfg.enable {
    services.monero.enable = true;
    services.monero.mining.enable = false;
  };
}