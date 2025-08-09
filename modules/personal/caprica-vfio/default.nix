##
# Motherboard: Gigabyte Aorus AX370-Gaming K7
# BIOS Settings:
# - Peripherals -> AMD CBS -> ACS enable
# - Frequency Settings -> Advanced CPU Settings -> SVM enable
#   - SVM == secure virtual machine (AMD's VT-d)
# - Chipset -> IOMMU enable
# - Enable CSM
#   - For some reason, this causes vgaarb to use the lower GPU
#     (0000:09:00.0) as the "boot VGA device" which is what we want...
#     With it disabled, it uses the upper one (0000:08:00.0)
#     which breaks the passthrough.
#
# Do NOT go above BIOS version F50A, F50E+ removes the ACS/AER options
#
# With the above settings, the top PCIe port is 0000:08:00.X, the bottom
# is 0000:09:00.X.
#
# Useful stuff:
# - echo 0 > /sys/devices/virtual/vtconsole/vtcon1/bind
# - echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind 
# - https://www.kernel.org/doc/Documentation/console/console.txt
#
##
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
  boot.initrd.availableKernelModules = [ "vfio-pci" ];
  boot.initrd.preDeviceCommands = ''
    DEVS="0000:08:00.0 0000:08:00.1"
    for DEV in $DEVS; do
      echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
    done
    modprobe -i vfio-pci
  '';

  boot.kernelParams  = [ "amd_iommu=on" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.blacklistedKernelModules = [ "nouveau" ];

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
