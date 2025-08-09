{ config, pkgs, lib, ... }:
let
  usesNullmailer = config.services.nullmailer.enable && config.services.nullmailer.setSendmail;
in
{
  options.systemd.services = with lib; mkOption {
    type = types.attrsOf(types.submodule({ name, config, ... }: {
      options.confinement.configureSendmail = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Allow using the system sendmail.
        '';
      };

      config = lib.mkIf config.confinement.configureSendmail {
        confinement.packages = [
          pkgs.system-sendmail
        ] ++ lib.optionals usesNullmailer [
          pkgs.nullmailer # Needs its sendmail and nullmailer-inject
        ];

        path = [
          pkgs.system-sendmail
        ];

        serviceConfig = {
          BindReadOnlyPaths = [
            "/run/wrappers/bin/sendmail"
          ];

          BindPaths = lib.optionals usesNullmailer [
            "/var/spool/nullmailer"
          ];
        };
      };
    }));
  };
}
