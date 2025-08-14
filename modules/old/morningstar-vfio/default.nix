{ config, pkgs, ... }:
let
  lsiommu = pkgs.writeShellScriptBin "lsiommu" ''
    shopt -s nullglob

    for g in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do
        echo "IOMMU Group ''${g##*/}:"
        for d in $g/devices/*; do
            echo -e "\t$(lspci -nns ''${d##*/})"
        done
    done
  '';
in
{
  nixpkgs.overlays = [
    (self: super: {
      looking-glass-client = super.looking-glass-client.overrideAttrs(old: rec {
        version = "B6";
        src = super.fetchFromGitHub {
          owner = "gnif";
          repo = "LookingGlass";
          rev = version;
          hash = "sha256-6vYbNmNJBCoU23nVculac24tHqH7F4AZVftIjL93WJU=";
          fetchSubmodules = true;
        };

        postUnpack = ''
          echo $version > source/VERSION
          export sourceRoot="source/client"
        '';
      });
    })
  ];

  boot.initrd.kernelModules = [ "kvmgt" "vfio-iommu-type1" "mdev" ];

  boot.initrd.preDeviceCommands = ''
    echo 6f33cc3d-6923-4711-b795-795e12455c72 > /sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create
  '';

  boot.kernelParams  = [ "intel_iommu=on" "iommu=pt" ];
  boot.kernelModules = [ "kvm_intel" ];

  virtualisation.libvirtd = {
    enable           = true;
    qemu.ovmf.enable = true;
    qemu.runAsRoot   = false;
    onBoot           = "ignore";
    onShutdown       = "shutdown";
  };

  # scream -vv -i virbr0
  # looking-glass-client -F -f /dev/shm/looking-glass
  environment.systemPackages = with pkgs; [
    lsiommu
    looking-glass-client
    scream
  ];

  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 ${config.settings.primaryUser.username} qemu-libvirtd -"
  ];
}
