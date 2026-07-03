{ config, lib, ... }:
{
  options.cadance.settings = with lib; {
    localNetworks = mkOption {
      type = types.listOf types.str;
      default = [ "192.0.0.0/24" "10.0.0.0/8" ];
    };

    noreplyEmail = mkOption {
      type = types.str;
      default = "noreply@example.com";
    };

    noreplyEmailFull = mkOption {
      type = types.str;
      default = "noreply <noreply@example.com>";
    };

    notifyEmails = mkOption {
      type = types.listOf types.str;
      default = [ "notify@example.com" ];
    };

    notifyEmailsFull = mkOption {
      type = types.listOf types.str;
      default = [ "Notify <notify@example.com>" ];
    };

    musicMountPath = mkOption {
      type = types.str;
      default = "/storage/SyncRoot/Music";
    };
  };
}
