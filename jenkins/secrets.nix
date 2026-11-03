{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    # Bootstrap this identity through nixos-anywhere --extra-files.
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];

    secrets = {
      oauth2_proxy_client_secret = {
        owner = "oauth2-proxy";
        mode = "0400";
        restartUnits = [ "oauth2-proxy.service" ];
      };
      oauth2_proxy_cookie_secret = {
        owner = "oauth2-proxy";
        mode = "0400";
        restartUnits = [ "oauth2-proxy.service" ];
      };
    };
  };
}
