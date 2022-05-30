##
# CADANCE modules to run a PostgreSQL container.
#
# TODO: Change users to an attrset instead of a list.
##
{ config, pkgs, lib, ... }:
let
  cfg = config.cadance.containers.postgresql;
in {
  options.cadance.containers.postgresql = with lib; {
    enable = mkEnableOption "Enable PostgreSQL container";

    containerName = mkOption {
      type = types.str;
      default = "postgresql";
    };

    hostAddress = mkOption {
      type = types.str;
    };

    localAddress = mkOption {
      type = types.str;
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/postgresql";
    };

    uid = mkOption {
      type = types.int;
      default = config.ids.uids.postgres;
    };

    gid = mkOption {
      type = types.int;
      default = config.ids.gids.postgres;
    };

    users = mkOption {
      type = types.listOf (types.submodule({
        options = {
          name = mkOption {
            type = types.str;
          };

          trustCIDRs = mkOption {
            type = types.listOf types.str;
            default = [];
          };

          createDatabase = mkOption {
            type = types.bool;
            default = true;
          };
        };
      }));

      default = [];
    };

    extraAuth = mkOption {
      type = types.str;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {

    users.groups.postgres.gid = lib.mkForce cfg.gid;
    users.users.postgres = {
      ##
      # NB: mkForce is needed to override NixOS's defaults.
      # We're not running postgres on the host itself, so this is fine.
      ##
      isSystemUser = lib.mkForce true;
      group        = lib.mkForce "postgres";
      uid          = lib.mkForce cfg.uid;
      home         = lib.mkForce cfg.stateDir;
    };

    systemd.tmpfiles.rules = [
      "d '${cfg.stateDir}' 0700 postgres postgres -"
    ];

    networking.nat.internalInterfaces   = [ "ve-${cfg.containerName}" ];
    networking.networkmanager.unmanaged = [ "interface-name:ve-${cfg.containerName}" ];

    containers.${cfg.containerName} = {
      autoStart      = true;
      ephemeral      = true;
      privateNetwork = true;
      hostAddress    = cfg.hostAddress;
      localAddress   = cfg.localAddress;

      bindMounts."/var/lib/postgresql" = {
        hostPath   = cfg.stateDir;
        isReadOnly = false;
      };

      config = { config, pkgs, ... }: {
        users.groups.postgres.gid = lib.mkForce cfg.gid;
        users.users.postgres = {
          isSystemUser = lib.mkForce true;
          uid          = lib.mkForce cfg.uid;
          group        = lib.mkForce "postgres";
          home         = lib.mkForce "/var/lib/postgresql";
        };

        networking.firewall.allowedTCPPorts = [ config.services.postgresql.port ];

        services.postgresql = let
          usersWithDatabases = builtins.filter (u: u.createDatabase) cfg.users;
        in {
          enable      = true;
          enableTCPIP = true;

          ensureDatabases = builtins.map (x: x.name) usersWithDatabases;

          ensureUsers = builtins.map (x: {
            name = x.name;
            ensurePermissions = lib.optionalAttrs x.createDatabase {
              "DATABASE ${x.name}" = "ALL PRIVILEGES";
            };
          }) usersWithDatabases;

          authentication = let
            trustLines = lib.flatten (builtins.map (x:
              builtins.map (y: "host all ${x.name} ${y} trust") x.trustCIDRs
            ) usersWithDatabases);
          in lib.mkForce ''
            ##
            # Automatically generated file, do not edit.
            ##

            # For the local postgres user
            local all all peer

            ${builtins.concatStringsSep "\n" trustLines}

            ${cfg.extraAuth}
          '';
        };

        system.stateVersion = "21.11";
      };
    };
  };
}
