# dotfiles

Ubuntu provisioning system — installs packages and applies dotfiles on fresh installs via declarative YAML.

## Features

- Declarative YAML-based configuration
- Profile dispatch for different machine types
- Idempotent provisioning (safe to run multiple times)
- Version-controlled package lists and dotfiles
- No external dependencies beyond standard Ubuntu packages

## Usage

```bash
./provision.sh [profile]
```

Profiles: `workstation`, `minimal`, `server`

## Files

- `packages/` — declarative package lists per profile
- `dotfiles/` — dot configuration files (bash, git, vim, etc.)
- `provision.sh` — main provisioning script
- `.gitlab-ci.yml` — automated testing on fresh images

## Roadmap

See [ROADMAP.md](ROADMAP.md) for next priorities.

## Contributing

Submit changes via merge request. All changes must pass the fresh-image test in CI.
