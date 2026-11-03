{
  # Example x86_64 UEFI host. Adapt the boot and hardware settings for your machine.
  system.stateVersion = "26.11";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "sd_mod"
  ];
  hardware.enableRedistributableFirmware = true;

  networking = {
    hostName = "jenkins";
    # Configure static addresses or provider-specific routes here if needed.
    useDHCP = true;
    # Caddy in the Jenkins module handles HTTPS and certificate issuance.
    firewall.allowedTCPPorts = [
      22
      80
      443
    ];
  };

  time.timeZone = "UTC";
}
