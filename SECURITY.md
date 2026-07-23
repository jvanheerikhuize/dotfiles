# Security Policy

## Reporting a Vulnerability

If you discover a security issue in these scripts, please report it privately
rather than opening a public issue:

1. **Do not** open a public GitHub issue.
2. Email the maintainer (see [README.md](README.md) for contact).
3. Include a description, steps to reproduce, and the potential impact.

You'll get an acknowledgment as soon as practical. This is a personal
provisioning repo, not a funded project — there is no formal SLA, but security
reports are taken seriously and prioritised over feature work.

## What this repo does with your machine

Being honest about the trust model matters more than a checklist:

- **It runs `sudo` for package installs.** `install.sh` is not run as root, but
  individual `apt`/`snap`/`dpkg` steps call `sudo`. Read the profile YAML and the
  `src/*.sh` you're about to run before running them.
- **`deb` and `custom` packages execute third-party code.** A `deb` entry
  downloads a `.deb` over HTTPS and installs it; a `custom` entry runs an
  arbitrary shell command. Only add sources you trust, and pin URLs to a specific
  version rather than a moving "latest".
- **It generates an SSH keypair and a git identity.** `setup-ssh.sh` creates
  `~/.ssh/id_ed25519` (private key `600`, `~/.ssh` `700`) and, in
  `--non-interactive` mode, generates it **without a passphrase**. Prefer an
  interactive run so you can set one.
- **`--force` overwrites dotfiles**, backing the originals up to `.bak`. Without
  `--force`, existing files are left untouched.

## Best practices for contributors

1. **Never commit secrets** — no keys, tokens, or passwords. Check `.gitignore`
   before staging.
2. **Pin external sources** — `deb` URLs and `custom` commands should reference a
   specific, verifiable version, not a mutable endpoint.
3. **Least privilege** — only reach for `sudo` in the specific step that needs it;
   never wrap the whole script.
4. **Quote and validate** — quote all variable expansions; run `shellcheck` before
   opening a PR (see [CONTRIBUTING.md](CONTRIBUTING.md)).
