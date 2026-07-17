# dotfiles

Portable machine config, symlinked into `$HOME`. The repo is the source of
truth — there is no sync step, so nothing drifts.

## New device

```bash
git clone git@github.com:ehulewicz/dotfiles.git
cd dotfiles && ./bootstrap.sh
```

`bootstrap.sh` is idempotent: it backs up any real file it replaces
(`~/<file>.pre-dotfiles.bak`), symlinks the managed files, and creates the
empty `.local` override files. Re-run it after adding a new managed file.

## Managed files

| Repo file | Linked to | Notes |
|---|---|---|
| `.bashrc` | `~/.bashrc` | Portable core; sources `~/.bashrc.local` at the end |
| `.gitconfig` | `~/.gitconfig` | Identity + include tiers |

## Three config tiers

1. **Versioned core** — the files in this repo. Most changes go here.
2. **Machine-local, never committed** — `~/.bashrc.local`, `~/.gitconfig.local`.
   Work aliases, SSH/key setup, device-specific hosts. The core files source /
   include these if present.
3. **Project-local, versioned in that project** — git config scoped to one
   project via `includeIf` (e.g. `~/personal-os/.gitconfig` lives in and is
   committed to personal-os, not here).

## Roadmap

Later passes will add the agent-workflow layer from the ground up: shared
Claude Code / Codex instructions and skills, MCP registration in bootstrap,
and a unified script layer. Deliberately not started yet.
