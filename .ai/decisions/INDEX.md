# ADR Index

Living index of all Architecture Decision Records in this project.

> **AI Assistants**: When you create a new ADR, add a row here immediately. Use the next sequential number.

| ADR | Title | Status | Date | Summary |
|-----|-------|--------|------|---------|
| [ADR-001](ADR-001-ed25519-key-type.md) | Use ed25519 Key Type for SSH Keypair Generation | Accepted | 2026-02-26 | ed25519 chosen over RSA/ECDSA for better security, shorter keys, and broad modern compatibility |
| [ADR-002](ADR-002-non-interactive-no-passphrase.md) | No Passphrase for SSH Key in Non-Interactive Mode | Accepted | 2026-02-26 | Pass `-N ""` to ssh-keygen when NON_INTERACTIVE=true; emit visible warning; interactive mode still prompts |
| [ADR-003](ADR-003-openssh-client-in-base-profile.md) | Add openssh-client to Base Profile (Not Dockerfile Only) | Accepted | 2026-02-26 | openssh-client added to both base.yaml and Dockerfile; --dotfiles-only tests need it pre-installed |

---

**Next ADR number: 004**
