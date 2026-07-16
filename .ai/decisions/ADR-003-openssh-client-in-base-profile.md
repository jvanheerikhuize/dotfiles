# ADR-003: Add openssh-client to Base Profile (Not Dockerfile Only)

## Status

Accepted

## Date

2026-02-26

## Context

FEAT-0009 requires `ssh-keygen` to be available at provisioning time. `ssh-keygen` is provided by the `openssh-client` apt package (not `ssh`, which is a metapackage).

There were two locations where this dependency could be declared:

1. **`profiles/base.yaml`** — the provisioner's package list; installed by `install.sh` during a full run
2. **`tests/smoke/Dockerfile`** — the Docker image bootstrap layer; available in all test scenarios regardless of how `install.sh` is invoked

The SSH smoke tests run with `--dotfiles-only`, which bypasses the package installation step. This means `openssh-client` from `base.yaml` would NOT be installed during smoke tests — `ssh-keygen` would be missing.

During FEAT-0009 CI, this manifested as:
```
ssh-keygen: command not found
```

in the `test-ssh-key-fresh` scenario, even though `openssh-client` was in `base.yaml`.

## Decision

We will add `openssh-client` to **both**:

1. `profiles/base.yaml` — so it is installed on real machines during a full provisioning run (correct for production use)
2. `tests/smoke/Dockerfile` — so it is available in the test container for scenarios that use `--dotfiles-only`

```yaml
# profiles/base.yaml
packages:
  apt:
    - openssh-client   # provides ssh-keygen, ssh-copy-id, ssh
```

```dockerfile
# tests/smoke/Dockerfile
RUN apt-get install -y \
    sudo git python3 python3-yaml openssh-client
```

## Consequences

### Positive

- `openssh-client` is installed on all provisioned machines via `base.yaml` — correct for any developer workstation
- All smoke tests have `ssh-keygen` available regardless of which `--dotfiles-only` / `--profile` combination they use
- The Dockerfile explicitly documents which tools are required for testing, making the dependency visible and intentional

### Negative

- `openssh-client` adds a small (~5 MB) apt package to the base profile for all machines, including server profiles. It is lightweight and standard enough that this is acceptable.
- The dependency is declared in two places; if the package name ever changes, both must be updated. (Mitigation: the apt package name `openssh-client` is stable.)

### Neutral

- `openssh-client` is installed by default on most Ubuntu 22.04 desktop images; adding it explicitly makes the provisioner self-sufficient on minimal server installs too

## Alternatives Considered

### Option 1: Add only to Dockerfile, not base.yaml

- **Pros**: Keeps base.yaml focused on user-facing packages; avoids "adding to base for tests"
- **Cons**: Real machines provisioned without the test image would not have `ssh-keygen`; `setup-ssh.sh` would fail on a minimal Ubuntu 22.04 server install
- **Why rejected**: The provisioner must be self-sufficient — it cannot depend on `ssh-keygen` being pre-installed.

### Option 2: Add only to base.yaml, not Dockerfile

- **Pros**: Single source of truth; consistent with "tests replicate real provisioning"
- **Cons**: SSH tests use `--dotfiles-only` (necessary because installing all apt packages in Docker is slow and the test focuses on SSH setup, not package installation); this leaves `ssh-keygen` unavailable
- **Why rejected**: This was the original approach and caused the CI failure. Smoke tests that focus on a specific script need that script's dependencies pre-installed in the image.

### Option 3: Change SSH tests to use full provisioning (not --dotfiles-only)

- **Pros**: Would install `openssh-client` via base.yaml, removing the need for Dockerfile change
- **Cons**: Full provisioning in Docker installs many apt packages, making tests much slower and more fragile (network dependencies, snap issues in containers)
- **Why rejected**: The smoke test framework is deliberately lightweight. `--dotfiles-only` isolation is the correct pattern for script-focused tests.

## References

- Ubuntu package: `openssh-client` (provides `/usr/bin/ssh-keygen`, `/usr/bin/ssh`, `/usr/bin/ssh-copy-id`)
- FEAT-0009 spec: `specs/features/FEAT-0009-ssh-key-setup.yaml`
- CI failure: PR #10, run 2 — `ssh-keygen: command not found`
- Implementation: `profiles/base.yaml`, `tests/smoke/Dockerfile`

---

## Notes

This is a retrospective ADR. The decision was made during FEAT-0009 CI remediation (Session 001, 2026-02-26) — specifically during the Bug 2 fix — but the ADR was not created at the time due to DIRECTIVES.md still containing template placeholders. Created retroactively as part of FEAT-0016.
