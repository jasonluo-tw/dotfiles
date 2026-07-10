#!/usr/bin/env bash
# Symlink every dotfile in this repo into the right place under $HOME.
# Existing real files are backed up to <file>.bak-<timestamp> before linking.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"

# Tools these dotfiles need. Zim, powerlevel10k and lazy.nvim self-bootstrap
# (from .zshrc / plugins.lua) so they are NOT listed here.
PKGS=(neovim fzf bat tmux)

install_packages() {
  read -rp "Install tools (${PKGS[*]})? [y/N] " ans
  case "$ans" in
    [Yy]*) ;;
    *) echo "Skipping package install."; return ;;
  esac

  case "$(uname -s)" in
    Darwin)
      if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
      brew install "${PKGS[@]}"
      ;;
    Linux)
      # `make` is needed to build avante.nvim's native lib; on macOS it comes
      # with the Xcode Command Line Tools, so it's only added here for Linux.
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y "${PKGS[@]}" make
        # Debian/Ubuntu ship bat as `batcat`; the fzf preview in nvim calls `bat`.
        command -v bat >/dev/null 2>&1 || \
          { b="$(command -v batcat 2>/dev/null)" && [ -n "$b" ] && sudo ln -sf "$b" /usr/local/bin/bat; }
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "${PKGS[@]}" make
      elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm "${PKGS[@]}" make
      else
        echo "No supported package manager (apt/dnf/pacman). Install manually: ${PKGS[*]} make"
      fi
      ;;
    *)
      echo "Unsupported OS '$(uname -s)'. Install manually: ${PKGS[*]}"
      ;;
  esac
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
