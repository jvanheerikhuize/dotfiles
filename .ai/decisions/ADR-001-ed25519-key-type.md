# ADR-001: Use ed25519 Key Type for SSH Keypair Generation

## Status

Accepted

## Date

2026-02-26

## Context

FEAT-0009 requires `src/setup-ssh.sh` to generate an SSH keypair for the user. The SSH protocol supports multiple key types: RSA (2048/4096-bit), ECDSA (256/384/521-bit), and ed25519.

The provisioner targets Ubuntu 22.04 with OpenSSH 8.x as the client and expects the resulting public key to be registered on GitHub (primary use case). The provisioner runs as a non-root user on a fresh developer workstation.

Key requirements:
- Modern, secure algorithm with long-term support
- Compatible with GitHub and other major Git hosting providers
- Shorter key file (easier to copy/paste the public key)
- Supported by all major SSH servers in active use (OpenSSH 6.5+ = 2014)

## Decision

We will use `ssh-keygen -t ed25519` to generate the SSH keypair.

The key comment will be set to `${USER}@$(hostname)` for easy identification when the public key is added to GitHub or other services.

```bash
ssh-keygen -t ed25519 \
  -f "${KEY_PATH}" \
  -C "${USER}@$(hostname)" \
  -N "${passphrase}"
```

## Consequences

### Positive

- ed25519 is based on Curve25519 — currently considered the most secure and well-audited elliptic curve option
- Shorter keys: a 68-character public key vs 544+ characters for RSA-4096
- Faster signing and verification than RSA
- GitHub, GitLab, Bitbucket, and all major SSH servers support ed25519
- `ssh-keygen -t ed25519` is the recommendation in GitHub's own SSH key documentation

### Negative

- Incompatible with legacy SSH servers running OpenSSH < 6.5 (released 2014); extremely unlikely to be relevant for a 2024+ developer workstation
- Some older enterprise VPN appliances may not support ed25519; users needing RSA for those systems will need to generate a second key manually

### Neutral

- Key file location (`~/.ssh/id_ed25519` / `~/.ssh/id_ed25519.pub`) follows the default `ssh-keygen` naming convention for ed25519, so `ssh` picks it up automatically without config entries

## Alternatives Considered

### Option 1: RSA-4096

- **Pros**: Maximum compatibility with any SSH server, including ancient ones; widely understood
- **Cons**: 4096-bit key files are much larger; slower signing; RSA's security depends on the factoring problem which has weaker long-term assurance than elliptic curves
- **Why rejected**: ed25519 is more secure, faster, and produces shorter keys. RSA compat concerns are irrelevant for a developer workstation targeting modern infrastructure.

### Option 2: ECDSA (P-256)

- **Pros**: Also elliptic curve; wider support window than ed25519
- **Cons**: P-256/P-384 curve parameters originate from NIST; there are well-known concerns about potential backdoor weaknesses in the constants. ed25519's Curve25519 was independently designed with publicly verifiable parameters.
- **Why rejected**: ed25519 has better trust properties and is now equally well supported.

## References

- [GitHub SSH key docs](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
- [OpenSSH 6.5 release notes (ed25519 introduction)](https://www.openssh.com/txt/release-6.5)
- FEAT-0009 spec: `specs/features/FEAT-0009-ssh-key-setup.yaml`
- Implementation: `src/setup-ssh.sh`

---

## Notes

This is a retrospective ADR. The decision was made during FEAT-0009 implementation (Session 001, 2026-02-26) but the ADR was not created at the time due to DIRECTIVES.md still containing template placeholders. Created retroactively as part of FEAT-0016.
