# ADR-002: No Passphrase for SSH Key in Non-Interactive Mode

## Status

Accepted

## Date

2026-02-26

## Context

FEAT-0009's `src/setup-ssh.sh` generates an SSH keypair. In interactive mode (default), the user can be prompted for a passphrase. In non-interactive mode (`NON_INTERACTIVE=true` or `--non-interactive` flag), there is no TTY available for `ssh-keygen` to prompt the user.

Non-interactive mode is required by:
1. Smoke tests running in Docker containers (no TTY)
2. Automated provisioning scripts that pipe input to `install.sh`
3. CI/CD environments

`ssh-keygen` will hang indefinitely if it expects passphrase input and no input is available. Passing `-N ""` explicitly sets an empty passphrase (no passphrase).

The alternative — prompting the user — is impossible without a TTY, and attempting it would cause `ssh-keygen` to block the entire provisioning run.

## Decision

In non-interactive mode (`NON_INTERACTIVE=true`), we will pass `-N ""` to `ssh-keygen` to generate a passphrase-free key, and emit a visible warning:

```bash
if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
  log_warn "Non-interactive mode: generating SSH key without a passphrase."
  log_warn "Add a passphrase later with: ssh-keygen -p -f ${KEY_PATH}"
  passphrase=""
else
  # prompt user for optional passphrase
  read -rsp "Enter passphrase (empty for no passphrase): " passphrase
fi

ssh-keygen -t ed25519 -f "${KEY_PATH}" -C "${comment}" -N "${passphrase}"
```

In interactive mode, the user is prompted and can choose to set a passphrase or leave it empty.

## Consequences

### Positive

- Smoke tests and automated provisioning work correctly without hanging
- The warning is explicit: the user is informed and given the remediation command
- Interactive mode still supports passphrases — no regression for human-driven installs

### Negative

- A passphrase-free SSH key has weaker protection if the key file is stolen; the key can be used immediately without the passphrase
- Users who run non-interactive mode on a real machine (not a test) and don't notice the warning will have a less-secure key

### Neutral

- GitHub and most services work identically with or without a passphrase on the private key; the public key registration workflow is unaffected
- The key can be upgraded to have a passphrase at any time: `ssh-keygen -p -f ~/.ssh/id_ed25519`

## Alternatives Considered

### Option 1: Always require a passphrase (reject non-interactive mode for SSH)

- **Pros**: Forces stronger key security
- **Cons**: Breaks all smoke tests and automated provisioning; contradicts the purpose of `--non-interactive`
- **Why rejected**: Non-interactive mode must complete unattended; this option makes it impossible.

### Option 2: Skip SSH key generation entirely in non-interactive mode

- **Pros**: No security trade-off
- **Cons**: Makes smoke tests unable to verify AC-001 through AC-005 (the core SSH setup functionality); skipping generation silently fails to provision the key
- **Why rejected**: The smoke tests need to verify that key generation works; skipping it defeats the purpose of the test.

### Option 3: Generate a random passphrase and discard it (key becomes unusable)

- **Pros**: Key file on disk cannot be used (passphrase unknown)
- **Cons**: Completely useless for the provisioning purpose; a key you cannot use is worse than no key
- **Why rejected**: Nonsensical for production use.

## References

- `ssh-keygen(1)` man page: `-N new_passphrase`
- FEAT-0009 spec AC-005: `specs/features/FEAT-0009-ssh-key-setup.yaml`
- Implementation: `src/setup-ssh.sh` function `_generate_keypair()`

---

## Notes

This is a retrospective ADR. The decision was made during FEAT-0009 implementation (Session 001, 2026-02-26) but the ADR was not created at the time due to DIRECTIVES.md still containing template placeholders. Created retroactively as part of FEAT-0016.
