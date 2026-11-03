{ config, ... }:
{
  imports = [
    ../common/admin.nix
    ./disk-config.nix
    ./hardware.nix
    ./devices.nix
    ./secrets.nix
  ];

  networking.hostName = "testagent";
  networking.useDHCP = true;
  system.stateVersion = "26.11";
  time.timeZone = "UTC";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  hardware.enableRedistributableFirmware = true;
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  services.testagent = {
    enable = true;
    variant = "dev";
    devices = [
      "lenovo-x1"
      "darter-pro"
    ];
    controllerSshKeyFile = config.sops.secrets.jenkins-agent-key.path;
    provenanceTrustPolicyFile = ../policies/provenance-trust-policy.yaml;
    testCredentialFiles = {
      dut-pass = config.sops.secrets.dut-pass.path;
      switch-token = config.sops.secrets.switch-token.path;
      switch-secret = config.sops.secrets.switch-secret.path;
    };
    tooling = {
      relayboard = false;
      usbSdmux.enable = false;
    };
  };
}
