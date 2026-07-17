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

echo "Done. Open a new shell (or 'source ~/.bashrc') to pick up changes."
