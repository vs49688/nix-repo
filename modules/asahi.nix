{ pkgs, utils, ... }: {
  nix.settings.extra-substituters = [
    "https://nixos-apple-silicon.cachix.org"
  ];

  nix.settings.extra-trusted-public-keys = [
    "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
  ];

  boot.kernelParams = [
    # Make the function keys function.
    "hid_apple.fnmode=2"
  ];

  systemd.services.set-battery-threshold = {
    description = "set battery charge threshold";

    confinement.enable = true;
    confinement.mode = "full-apivfs";
    confinement.binSh = null;

    wantedBy = [ "multi-user.target" ];

    unitConfig.ConditionPathExists = "/sys/class/power_supply/macsmc-battery/charge_control_end_threshold";

    serviceConfig.ExecStart = let
      args = [
        "-c"
        "echo 80 > /sys/class/power_supply/macsmc-battery/charge_control_end_threshold"
      ];
    in ''
      ${pkgs.bash}/bin/sh ${utils.escapeSystemdExecArgs args}
    '';

    serviceConfig.Type = "oneshot";
    serviceConfig.User = "root";
    serviceConfig.Group = "root";
    serviceConfig.RemainAfterExit = true;
    serviceConfig.BindPaths = [ "/sys/class/power_supply/macsmc-battery" ];
  };
}
