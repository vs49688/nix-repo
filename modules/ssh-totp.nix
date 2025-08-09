{ lib, ... }:

{
  # A disgustingly beautiful hack from https://github.com/NixOS/nixpkgs/issues/164357
  options.security.pam.services = with lib; mkOption {
    type = types.attrsOf (types.submodule {
      # Instead of overriding options.*.default, set it in the config section of the module
      config.oathAuth = mkDefault false;
    });
  };

  config = {
    security.pam.services.sshd.oathAuth = true;

    # https://wiki.archlinux.org/title/Pam_oath
    security.pam.oath.enable = true;

    services.openssh = {
      settings.PasswordAuthentication = true;
    } // (if (lib.versionAtLeast (lib.versions.majorMinor lib.version) "22.05") then {
      settings.KbdInteractiveAuthentication = true;
    } else {
      settings.ChallengeResponseAuthentication = true;
    });
  };
}
