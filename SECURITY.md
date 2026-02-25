# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please report it responsibly.

### How to Report

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Email security concerns to the repository maintainer (see [README.md](README.md) for contact info)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes (optional)

### What to Expect

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 5 business days
- **Resolution Timeline**: Depends on severity
  - Critical: 24-48 hours
  - High: 1 week
  - Medium: 2 weeks
  - Low: Next release cycle

### Security Best Practices for Contributors

When contributing to this repository:

1. **Never commit secrets**
   - No API keys, passwords, or credentials
   - Use environment variables or secret management
   - Review `.gitignore` before committing

2. **Validate inputs**
   - Sanitize user inputs
   - Validate spec files before processing
   - Use parameterized queries for databases

3. **Dependency management**
   - Keep dependencies updated
   - Review security advisories
   - Use lockfiles for reproducible builds

4. **Code review**
   - All changes require review
   - Security-sensitive changes need additional scrutiny
   - Follow the principle of least privilege

## Security Features

This template includes:

- **Spec validation**: All specifications are validated against schemas
- **CODEOWNERS**: Required reviews for sensitive files
- **Branch protection**: Recommended for production use
- **Secret scanning**: Enable GitHub secret scanning
- **Dependabot**: Recommended for dependency updates

## Configuring Security

### Enable Branch Protection

1. Go to Settings > Branches
2. Add rule for `main` branch
3. Enable:
   - Require pull request reviews
   - Require status checks
   - Require signed commits (optional)

### Enable Security Features

1. Go to Settings > Security
2. Enable:
   - Dependency graph
   - Dependabot alerts
   - Dependabot security updates
   - Secret scanning

### Secret Management

For CI/CD:
- Use GitHub Secrets for sensitive values
- Rotate secrets regularly
- Use minimal permissions

For local development:
- Use `.env` files (never commit)
- Use secret managers when possible
