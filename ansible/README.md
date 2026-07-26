# Setup-Genie — Ansible

Production-style Ansible re-implementation of the Ubuntu/WSL side of Setup-Genie.
The legacy Bash (`../ubuntu/`) stays functional until each role reaches parity.

## Run model

Control-node-over-SSH: install Ansible on a control node, list your target
machines under the `workstations` group in `inventory/hosts.yml`, and run
playbooks against them over SSH. `localhost` (the `local` group) is wired up for
testing and self-bootstrap.

## Quick start

```bash
# 1. Prepare the control node (installs ansible-core + pinned collections)
bash ../bootstrap/bootstrap.sh

# 2. Always run from this directory (so ansible.cfg is picked up)
cd ansible

# 3. Smoke test connectivity
ansible -m ping all

# 4. Run the scaffold playbook
ansible-playbook site.yml
```

## Layout

| Path | Purpose |
|---|---|
| `ansible.cfg` | inventory path, roles path, output formatting, vault hook |
| `requirements.yml` | pinned Galaxy collections |
| `site.yml` | master playbook (imports section playbooks in later phases) |
| `inventory/hosts.yml` | `local` + `workstations` groups |
| `inventory/group_vars/all/` | `main.yml` (defaults), later `vars.yml` + vault.yml |
| `playbooks/` | one playbook per section (Phase 1+) |
| `roles/` | one role per tool/concern (Phase 1+) |

## Conventions (enforced as roles are added)

- Escalate per-task with `become: true` — never globally. User-scoped tasks
  (ssh keys, dotfiles, git) run as `{{ target_user }}`, not root.
- Prefer native modules over `command`/`shell`; if you must shell out, add
  `creates:`/`changed_when:` to stay idempotent.
- REQUIRED roles always run; OPTIONAL roles are gated by membership in
  `enabled_optional`.
- Lint before committing: `yamllint .` and `ansible-lint`.

The full migration plan (phases, role mapping, pitfalls) lives outside the repo
in the planning notes.
