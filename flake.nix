{
  description = "Example Jenkins controller and standalone hardware test agent using Ghaf infrastructure modules";

  inputs = {
    ghaf-infra.url = "github:joinemm/ghaf-infra/pr-jenkins-more-options";
    # Use the same pinned Nixpkgs as the modules and their supporting packages.
    nixpkgs.follows = "ghaf-infra/nixpkgs";
    deploy-rs.follows = "ghaf-infra/deploy-rs";
  };

  outputs =
    {
      self,
      ghaf-infra,
      nixpkgs,
      deploy-rs,
      ...
    }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        jenkins = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit self; };
          modules = [
            ghaf-infra.inputs.disko.nixosModules.disko
            ghaf-infra.inputs.sops-nix.nixosModules.sops
            ghaf-infra.nixosModules.jenkins
            ghaf-infra.nixosModules.zramSwap
            ./jenkins/configuration.nix
          ];
        };
        testagent = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ghaf-infra.inputs.disko.nixosModules.disko
            ghaf-infra.inputs.sops-nix.nixosModules.sops
            ghaf-infra.nixosModules.testagent
            ./testagent/configuration.nix
          ];
        };
      };
      deploy = import ./deploy.nix { inherit self deploy-rs system; };
      checks.${system} = deploy-rs.lib.${system}.deployChecks self.deploy;
      apps.${system}.deploy = deploy-rs.apps.${system}.default;
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;
    };
}
