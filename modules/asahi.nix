{ pkgs, utils, ... }: {
  ##
  # Build the Asahi components — the kernel above all — as a cross derivation from
  # x86_64, so the x86 builder can produce them and this machine substitutes rather than
  # spending hours on it. The module re-imports nixpkgs with `crossSystem` and the same
  # overlay, so the derivation is one any x86 builder produces; ZAIR and ANGELUS agree on
  # it, so one build and one cache entry serve both.
  ##
  hardware.asahi.pkgsSystem = "x86_64-linux";

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

  # asahi-nvram write system:StartupMute=%01
  environment.systemPackages = with pkgs; [
    asahi-bless
    asahi-nvram
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
