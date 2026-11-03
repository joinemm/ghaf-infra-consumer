{
  self,
  deploy-rs,
  system,
}:
let
  mkNode = name: hostname: {
    inherit hostname;
    profiles.system = {
      user = "root";
      path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${name};
    };
  };
in
{
  sshUser = "admin";
  autoRollback = true;
  magicRollback = true;

  # Replace with the SSH addresses of your installed hosts.
  nodes = {
    jenkins = mkNode "jenkins" "jenkins.example.org";
    testagent = mkNode "testagent" "testagent.example.org";
  };
}
