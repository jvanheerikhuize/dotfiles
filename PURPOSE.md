# Purpose

**Problem:** Managing dotfiles and system configuration across development, server, and workstation profiles requires maintaining multiple configuration files while keeping common settings DRY and allowing easy customization.

**Audience:** System administrators and developers managing their own workstations or infrastructure, seeking declarative configuration management without a heavy orchestration tool.

**Key constraints:** Must be declarative (YAML-driven profile dispatch), support multiple profiles (base/desktop/server/dev), integrate with Autoinstall-YAML, and not require external secrets management for public configs.

**Success metric:** A developer can select a profile (e.g., "dev-workstation") and all dotfiles, packages, and settings are applied consistently without manual steps or divergence from the spec.
