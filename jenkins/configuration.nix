{ self, config, ... }:
let
  domain = "jenkins.example.org";
in
{
  imports = [
    ../common
    ./hardware.nix
    ./disk-config.nix
    ./secrets.nix
  ];

  services.ghaf-jenkins = {
    enable = true;
    envType = "dev";
    url = "https://${domain}";
    numExecutors = 2;

    # Empty means normal Nix builds on this host (or nix.buildMachines).
    remoteStores = { };
    registry.enable = false;
    artifacts.requireAuth = true;
    provenanceTrustPolicyFile = ../policies/provenance-trust-policy.yaml;
    releasePolicyFile = ../policies/release-policy.yaml;

    auth = {
      enable = true;
      inherit domain;
      clientID = "jenkins";
      oidcIssuerUrl = "https://auth.example.org";
      clientSecretFile = config.sops.secrets.oauth2_proxy_client_secret.path;
      cookieSecretFile = config.sops.secrets.oauth2_proxy_cookie_secret.path;
      groups = {
        authenticated = [
          "Overall/Read"
          "Job/Read"
        ];
        "ci-admins" = [ "Overall/Administer" ];
      };
    };

    agents.lab =
      let
        agentConfig = self.nixosConfigurations.testagent.config;
      in
      {
        enable = config.services.ghaf-jenkins.agents.lab.publicKey != null;
        hostName = agentConfig.networking.hostName;
        inherit (agentConfig.services.testagent) variant devices nodeNamePrefix;
        # Set the public key corresponding to the agent's jenkins-agent-key secret.
        publicKey = null;
      };

    jobs = {
      ghaf-build = {
        scriptFile = ./pipelines/ghaf-build.groovy;
        description = "Build consumer-defined targets using the ghafInfra shared library";
      };
      ghaf-hw-test = { };
      ghaf-hw-test-manual = { };
    };
  };
}
