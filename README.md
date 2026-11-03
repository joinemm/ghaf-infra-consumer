# Jenkins controller and hardware test agent

Example NixOS flake using [Ghaf infrastructure modules](https://github.com/joinemm/ghaf-infra/tree/pr-jenkins-more-options).
It defines an x86_64 Jenkins controller (`jenkins`) and an Intel hardware test
workstation (`testagent`), with deploy-rs for updates. Both examples use UEFI.

## Configure

| File | Set before deployment |
| --- | --- |
| `common/admin.nix` | Administrator SSH public keys; the supplied list is empty |
| `jenkins/hardware.nix`, `testagent/hardware.nix` | Boot, hardware and network settings |
| `jenkins/disk-config.nix`, `testagent/disk-config.nix` | OS disk paths; installation erases these disks |
| `jenkins/configuration.nix` | Jenkins domain, OIDC issuer/client/admin group, build concurrency |
| `testagent/configuration.nix`, `testagent/devices.nix` | Device inventory, SSD serials, hub IDs, DUT addresses and tooling |
| `policies/*.yaml` | Jenkins builder URL and trust requirements |
| `deploy.nix` | Controller and agent SSH addresses |

Point DNS at the controller, allow TCP 80/443, and allow SSH from administrators
and the agent. Register `https://YOUR-JENKINS-HOST/oauth2/callback` with your OIDC
provider and include the `groups` claim. The `admin` user has passwordless sudo;
root SSH login and password authentication are disabled.

## Secrets

Replace the example recipients in `.sops.yaml` and regenerate both encrypted
secret files. Create separate host age identities outside the checkout:

```bash
jenkins_bootstrap=$(mktemp -d /tmp/jenkins-bootstrap.XXXXXX)
agent_bootstrap=$(mktemp -d /tmp/testagent-bootstrap.XXXXXX)
for bootstrap in "$jenkins_bootstrap" "$agent_bootstrap"; do
  install -d -m 0700 "$bootstrap/var/lib/sops-nix"
  age-keygen -o "$bootstrap/var/lib/sops-nix/key.txt"
done
```

For each host's SOPS rule, use its printed public recipient and your
administrator's public age recipient. Encrypt and edit the templates:

```bash
for host in jenkins testagent; do
  sops --encrypt --filename-override "$host/secrets.yaml" \
    "$host/secrets.example.yaml" > "$host/secrets.yaml"
  sops "$host/secrets.yaml"
done
```

Set the controller's OIDC client secret and a cookie secret generated with
`openssl rand -base64 32`. The agent needs `jenkins-agent-key`, `dut-pass`,
`switch-token`, and `switch-secret`. Generate its SSH identity separately:

```bash
agent_key_dir=$(mktemp -d /tmp/testagent-ssh.XXXXXX)
ssh-keygen -t ed25519 -N '' -f "$agent_key_dir/jenkins-agent"
```

Put the private key in `jenkins-agent-key` as a YAML multiline string and the
public key in `services.ghaf-jenkins.agents.lab.publicKey` in
`jenkins/configuration.nix`; this enables node registration.

Keep plaintext secrets and private keys outside this checkout: `path:.` copies
ignored files into the Nix store too. Back up the host age identities securely;
updates reuse `/var/lib/sops-nix/key.txt`.

## Install and connect

These commands erase the configured OS disks. Replace the target addresses:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake path:.#jenkins --extra-files "$jenkins_bootstrap" \
  --target-host root@YOUR-CONTROLLER-IP

nix run github:nix-community/nixos-anywhere -- \
  --flake path:.#testagent --extra-files "$agent_bootstrap" \
  --target-host root@YOUR-AGENT-IP
```

On the agent, run `connect https://YOUR-JENKINS-HOST` and verify both device nodes
appear online. Enrollment accepts the controller's current SSH host key.
Run `connect` with another URL to switch controllers, or `disconnect` to stop.

## Deploy updates

Run from your administration machine using the pinned [deploy-rs](https://github.com/serokell/deploy-rs) app:

```bash
nix flake check path:. --no-build
nix run path:.#deploy -- path:.#jenkins
nix run path:.#deploy -- path:.#testagent
# Or deploy both together:
nix run path:.#deploy -- --targets path:.#jenkins path:.#testagent
```

Deployments build locally, transfer the system closure over SSH as `admin`, and
activate as `root` with rollback enabled. Add `--remote-build` to build on the
target instead. The default local build platform is `x86_64-linux`.

## Pipelines and upstream

Edit targets in `jenkins/pipelines/ghaf-build.groovy`. The default job builds Ghaf
documentation; authenticated downloads are available under **Artifacts**.
Hardware jobs are registered, but automatic hardware tests also require registry
publishing, signing and provenance configuration. Jenkins settings are declared
in Nix; UI-only changes are reset on boot.

Update the upstream pin with `nix flake update ghaf-infra --flake path:.`.
For local module development, add
`--override-input ghaf-infra path:../ghaf-infra --no-write-lock-file` to Nix
commands. Keep the committed input GitHub-based.
