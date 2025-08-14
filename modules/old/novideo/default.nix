{ config, lib, ... }:
{
  config = {
    /* https://github.com/geminis3/nvidia-gpu-off */
    boot.kernelModules = [ "acpi_call" ];
    boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
    boot.blacklistedKernelModules = [ "nouveau" "nvidia" ];

    systemd.tmpfiles.rules = lib.optionals (config.networking.hostName == "MORNINGSTAR") [
      "w /proc/acpi/call - - - - \\\\_SB.PCI0.PEG0.PEGP._OFF"
      "w /sys/bus/pci/devices/0000\:01\:00.0/remove - - - - 1"
    ] ++ lib.optionals (config.networking.hostName == "BAST") [
      "w /proc/acpi/call - - - - \\\\_SB_.PCI0.RP05.PEGP._OFF"
      "w /sys/bus/pci/devices/0000\:04\:00.0/remove - - - - 1"
    ];
  };
}
