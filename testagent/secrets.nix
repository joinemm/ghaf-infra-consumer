{ lib, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
    secrets = lib.genAttrs [ "jenkins-agent-key" "dut-pass" "switch-token" "switch-secret" ] (_: {
      owner = "jenkins";
      mode = "0400";
      restartUnits = [ "start-agents.service" ];
    });
  };
}
