#!/usr/bin/env bash
# Symlink every dotfile in this repo into the right place under $HOME.
# Existing real files are backed up to <file>.bak-<timestamp> before linking.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"

# Tools these dotfiles need. Zim, powerlevel10k and lazy.nvim self-bootstrap
# (from .zshrc / plugins.lua) so they are NOT listed here.
BREW_PKGS=(neovim fzf bat tmux)

install_packages() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # put brew on PATH for the rest of this script (Apple Silicon default prefix)
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  echo "Installing packages (already-installed ones are skipped)..."
  brew install "${BREW_PKGS[@]}"
}

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

# --- 1. packages (skip with --link-only) -----------------------------------
if [ "${1:-}" = "--link-only" ]; then
  echo "Skipping package install (--link-only)."
else
  install_packages
fi

# --- 2. symlinks -----------------------------------------------------------
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
