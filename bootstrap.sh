#!/usr/bin/env bash
# Idempotent dotfiles installer. Safe to re-run anytime.
#
#   git clone git@github.com:ehulewicz/dotfiles.git && cd dotfiles && ./bootstrap.sh
#
# Symlinks the managed files from this repo into $HOME (backing up any real
# file it replaces to <file>.pre-dotfiles.bak) and creates empty ~/.bashrc.local
# / ~/.gitconfig.local for machine-specific config that stays out of git.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANAGED=(.bashrc .gitconfig)

for file in "${MANAGED[@]}"; do
  src="$REPO_DIR/$file"
  dest="$HOME/$file"

  if [ ! -f "$src" ]; then
    echo "SKIP  $file — missing from repo ($src)" >&2
    continue
  fi

  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    echo "OK    $dest already links to repo"
    continue
  fi

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    backup="$dest.pre-dotfiles.bak"
    if [ -e "$backup" ]; then
      backup="$dest.pre-dotfiles.$(date +%Y%m%d%H%M%S).bak"
    fi
    mv "$dest" "$backup"
    echo "BACKUP $dest -> $backup"
  fi

  ln -sfn "$src" "$dest"
  echo "LINK  $dest -> $src"
done

for local_file in "$HOME/.bashrc.local" "$HOME/.gitconfig.local"; do
  if [ ! -e "$local_file" ]; then
    touch "$local_file"
    echo "INIT  $local_file (machine-local, never committed)"
  fi
done

# --- MCP servers (Claude Code + Codex) -------------------------------------
# Registered only if the CLI is installed and the server isn't already there.
# github (remote HTTP): both tools authenticate with a PAT exported as
# GITHUB_MCP_PAT (put it in ~/.bashrc.local). OAuth doesn't work for either —
# GitHub's MCP server lacks dynamic client registration, which both CLIs'
# OAuth flows require. Claude expands ${GITHUB_MCP_PAT} at connect time.

if command -v claude >/dev/null 2>&1; then
  claude_mcp() { # name, then the add-args
    local name="$1"; shift
    if claude mcp get "$name" >/dev/null 2>&1; then
      echo "OK    claude mcp: $name already registered"
    else
      claude mcp add --scope user "$name" "$@" && echo "MCP   claude: added $name"
    fi
  }
  claude_mcp playwright -- npx @playwright/mcp@latest
  claude_mcp chrome-devtools -- npx chrome-devtools-mcp@latest --autoConnect
  claude_mcp github --transport http https://api.githubcopilot.com/mcp/ --header 'Authorization: Bearer ${GITHUB_MCP_PAT}'
else
  echo "SKIP  claude CLI not installed — no Claude MCP registration"
fi

if command -v codex >/dev/null 2>&1; then
  codex_mcp() { # name, then the add-args
    local name="$1"; shift
    if codex mcp get "$name" >/dev/null 2>&1; then
      echo "OK    codex mcp: $name already registered"
    else
      codex mcp add "$name" "$@" && echo "MCP   codex: added $name"
    fi
  }
  codex_mcp playwright -- npx @playwright/mcp@latest
  codex_mcp chrome-devtools -- npx chrome-devtools-mcp@latest --autoConnect
  codex_mcp github --url https://api.githubcopilot.com/mcp/ --bearer-token-env-var GITHUB_MCP_PAT
else
  echo "SKIP  codex CLI not installed — no Codex MCP registration"
fi

echo "Done. Open a new shell (or 'source ~/.bashrc') to pick up changes."
