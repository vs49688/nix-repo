# https://github.com/NixOS/nixpkgs/pull/252071
{ config, lib, ... }: {
  options.services.postgresql.ensureUsers = with lib; mkOption {
    type = types.listOf (types.submodule {
      options = {
        ensureRoles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = lib.mdDoc ''
            Roles to ensure for the user, specified as a list of strings.

            For more information on how to specify the role, see the
            [GRANT syntax](https://www.postgresql.org/docs/current/sql-grant.html).
            The attributes are used as `GRANT ''${role}.
          '';
          example = literalExpression ''
            [
              "pg_read_all_data"
              "pg_write_all_data"
            ]
          '';
        };
      };
    });
  };

  config = {
    systemd.services.postgresql-setup.postStart = lib.concatMapStrings (user: let
        userRoles = lib.concatStringsSep "," user.ensureRoles;
      in ''
        psql -tAc 'GRANT "${userRoles}" TO "${user.name}"'
      ''
    ) (lib.filter (user: lib.length user.ensureRoles != 0) config.services.postgresql.ensureUsers);
  };
}
