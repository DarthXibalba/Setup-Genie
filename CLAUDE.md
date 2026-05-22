# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Setup-Genie is a script orchestrator for bootstrapping development environments on Ubuntu Linux and Windows. It automates installation and configuration of dev tools, container runtimes, and shell environments. The two platforms are cleanly separated: `ubuntu/` uses Bash + JSON config, `windows/` uses PowerShell + Winget.

## Running the Setup

**Ubuntu (main entry point):**
```bash
bash ubuntu/setup.sh <section>
```
Sections defined in `ubuntu/config/env_setup.json`: `devtools`, `containers`, `ubuntu`, `ubuntu_vm`, `wsl`, `personal`

**Windows:**
```powershell
.\windows\InstallWindowsStack.ps1
```

**Fix Windows line endings on any script:**
```bash
bash remove-all-carriage-returns.sh
```

There is no build system, test framework, or CI pipeline — execution is manual and interactive.

## Architecture

### Ubuntu Side

`setup.sh` reads `env_setup.json` via `jq`, iterates the script list for the requested section, and executes each script. Scripts use `@` as a space placeholder in the JSON (converted to spaces at runtime). Required scripts run unconditionally; optional scripts prompt the user.

Every install script sources `helper-scripts/logging.sh` for colorized output and `helper-scripts/apt-get-install.sh` for idempotent package installation (skips if already installed). All scripts use `set -euo pipefail` — a failure in any required step aborts the entire run.

**Key config files:**
- `ubuntu/config/env_setup.json` — maps section names → ordered script lists (REQUIRED/OPTIONAL)
- `ubuntu/config/gitconfig.json` — git profiles (personal/work) with USERNAME, EMAIL, LOCALPATH, and repo lists; **excluded from git** since it contains credentials

**Profile files** (`ubuntu/profile/`) are symlinked/copied to `$HOME` during setup. `.nerdctl_aliases` wraps nerdctl with a fixed namespace and socket for container operations.

### Windows Side

`InstallWindowsStack.ps1` reads `windows/config/windows_stack.json` (REQUIRED/OPTIONAL package lists) and installs via `winget`. `CopyFilesToWSL2.ps1` handles file transfer into WSL2. Git multi-profile (personal/work) is handled by `helper-scripts/ConfigureGitUser.ps1`.

### Git Multi-Profile Pattern

`ubuntu/helper-scripts/init-git.sh` generates per-profile SSH keys and writes git config. `ubuntu/helper-scripts/clone-git-repos.sh` clones repos from the `gitconfig.json` profile definition. This pattern supports concurrent personal and work git identities on the same machine.

## Conventions

- **Idempotent installs**: Every `install-*.sh` checks whether the tool is already present before running
- **Logging**: Use functions from `helper-scripts/logging.sh` — `log_step`, `log_info`, `log_warn`, `log_error`, `log_success`
- **New install scripts**: Add the script path to the relevant section in `env_setup.json`; use `@` in place of spaces in paths
- **Deprecated scripts**: Move to `ubuntu/legacy/` rather than deleting
- **Secrets**: `gitconfig.json` (real credentials) is gitignored — only `gitconfig_template.json` is tracked

## Install Script Standard

All `ubuntu/scripts/install-*.sh` files **must** follow the pattern in [`ubuntu/scripts/install-TEMPLATE.sh`](ubuntu/scripts/install-TEMPLATE.sh).
**Copy that file as the starting point for every new install script.** Delete the comment scaffolding as you fill it in.

Key rules (all enforced by the template):
- `#!/bin/bash` + `set -e` — no exceptions
- Resolve helper paths relative to `script_dir` via `dirname "$(realpath "$0")"` — never hardcode paths
- Validate **logging.sh first** with plain `echo` (logger not sourced yet), then use `log_error` for every subsequent check
- `# shellcheck source=/dev/null` on every `source` line
- All package installs via `$apt_get_install` — **never raw `apt-get`**
- Section headers always use the `# =========================` / `# TITLE` / `# =========================` delimiter style
- Add idempotency guards wherever practical (version string match, `command -v`, or `[ ! -f ]` for config files / GPG keys)
- Logging via `log_info` / `log_warn` / `log_error` / `log_success` / `log_step` from logging.sh
- End every script with a **Post-install notes** section: `log_success` confirmation + `log_info` verify/test commands + `##` block for manual first-run steps

Reference examples (all in `ubuntu/scripts/`):
- `install-nerdctl.sh` — version-string idempotency guard, download + extract pattern, systemd service check
- `install-proton-vpn.sh` — GPG key + APT repo guards, multi-step dependency pattern
- `install-kvm-qemu-virtmanager.sh` — group membership, dotfile alias append, extensive post-install workflow docs

## Change Tracking

`golden-image-change-log.md` documents VM snapshot versions (Base → Dev) and records which tools were installed in each snapshot. Update this file when adding new install scripts that change the golden image state.
