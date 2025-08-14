{ config, lib, ... }: let
  cfg = config.settings;
in {
  options.settings = with lib; {
    primaryUser = mkOption {
      type = types.str;
      apply = x: cfg.users.${x};
    };

    users = mkOption {
      default = {};

      type = types.attrsOf(types.submodule {
        options = {
          fullName = mkOption {
            type = types.str;
          };

          username = mkOption {
            type = types.str;
          };

          email = mkOption {
            type = types.str;
          };

          home = mkOption {
            type = types.str;
          };

          authorizedKeys = mkOption {
            type = with types; listOf str;
            default = [];
          };

          gpgKeyId = mkOption {
            type = with types; str;
          };

          sshKeyPath = mkOption {
            type = with types; str;
          };
        };
      });
    };
  };
}
