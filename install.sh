#!/usr/bin/env bash
# Symlink every dotfile in this repo into the right place under $HOME.
# Existing real files are backed up to <file>.bak-<timestamp> before linking.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"

link() {  # link <source> <target>
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  ok    $dst"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak-$STAMP"
    echo "  backup $dst -> $dst.bak-$STAMP"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "  link  $dst -> $src"
}

# home/*  ->  ~/<name>   (dotfiles that live directly in $HOME)
for f in "$DOTFILES"/home/.*; do
  name="$(basename "$f")"
  [ "$name" = "." ] || [ "$name" = ".." ] && continue
  link "$f" "$HOME/$name"
done

# config/*  ->  ~/.config/<name>   (whole directories under ~/.config)
for d in "$DOTFILES"/config/*; do
  link "$d" "$HOME/.config/$(basename "$d")"
done

# Individual files inside app dirs that ALSO hold untracked runtime state
# (sessions, logs, auth) — so we link single files, never the whole directory.
link "$DOTFILES/claude/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
link "$DOTFILES/codex/config.toml"    "$HOME/.codex/config.toml"

echo "Done. Remember: secrets live in ~/.zsh_secrets (not tracked here)."
