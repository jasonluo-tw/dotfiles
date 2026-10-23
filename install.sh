#!/usr/bin/env bash
# Symlink every dotfile in this repo into the right place under $HOME.
# Existing real files are backed up to <file>.bak-<timestamp> before linking.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"

# Tools these dotfiles need. Zim, powerlevel10k and lazy.nvim self-bootstrap
# (from .zshrc / plugins.lua) so they are NOT listed here.
PKGS=(neovim fzf bat tmux ripgrep tree-sitter-cli)
NVIM_PYTHON_VERSION="${NVIM_PYTHON_VERSION:-3.14}"
NODE_MIN_VERSION="${NODE_MIN_VERSION:-22.22.2}"

# Powerlevel10k is configured with `nerdfont-v3`, so install its recommended
# font alongside the command-line tools. Keep this independent of Homebrew so
# the same setup works on macOS and Linux.
install_meslo_font() {
  local font_dir font_base style file installed=0
  local styles=(Regular Bold Italic "Bold Italic")

  case "$(uname -s)" in
    Darwin) font_dir="$HOME/Library/Fonts" ;;
    Linux)  font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts" ;;
    *)
      echo "Skipping MesloLGS NF font installation on unsupported OS '$(uname -s)'."
      return
      ;;
  esac

  font_base="https://github.com/romkatv/powerlevel10k-media/raw/master"
  mkdir -p "$font_dir"

  for style in "${styles[@]}"; do
    file="MesloLGS NF $style.ttf"
    if [ -f "$font_dir/$file" ]; then
      echo "  ok    $font_dir/$file"
      continue
    fi

    echo "  font  $file"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL -o "$font_dir/$file.tmp" "$font_base/${file// /%20}"
    elif command -v wget >/dev/null 2>&1; then
      wget -q -O "$font_dir/$file.tmp" "$font_base/${file// /%20}"
    else
      echo "Neither curl nor wget is available; cannot install $file." >&2
      return 1
    fi
    mv -f "$font_dir/$file.tmp" "$font_dir/$file"
    installed=1
  done

  if [ "$installed" -eq 1 ] && command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$font_dir"
  fi
}

install_uv() {
  # The standalone installer defaults to ~/.local/bin, which .zprofile already
  # puts on PATH. Disable profile edits because those files are managed here.
  export PATH="$HOME/.local/bin:$PATH"

  if command -v uv >/dev/null 2>&1; then
    echo "  ok    uv ($(uv --version))"
    return
  fi

  echo "Installing uv..."
  if command -v curl >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | \
      env UV_INSTALL_DIR="$HOME/.local/bin" UV_NO_MODIFY_PATH=1 sh
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- https://astral.sh/uv/install.sh | \
      env UV_INSTALL_DIR="$HOME/.local/bin" UV_NO_MODIFY_PATH=1 sh
  else
    echo "Neither curl nor wget is available; cannot install uv." >&2
    return 1
  fi

  command -v uv >/dev/null 2>&1 || {
    echo "uv installation finished, but uv is not available on PATH." >&2
    return 1
  }
}

install_nvim_python_host() {
  local nvim_data_dir python_host host_python
  nvim_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
  python_host="$nvim_data_dir/python-host"
  host_python="$python_host/bin/python"

  if [ -x "$host_python" ]; then
    echo "  ok    Neovim Python environment ($python_host)"
  else
    echo "Creating Neovim Python environment with Python $NVIM_PYTHON_VERSION..."
    uv venv "$python_host" \
      --python "$NVIM_PYTHON_VERSION" \
      --managed-python
  fi

  echo "Installing Neovim Python provider..."
  uv pip install --python "$host_python" --upgrade pynvim
  "$host_python" -c 'import pynvim; print("  ok    pynvim " + pynvim.__version__)'
}

version_at_least() {
  local current="$1" required="$2"
  local current_major current_minor current_patch
  local required_major required_minor required_patch

  IFS=. read -r current_major current_minor current_patch <<< "${current#v}"
  IFS=. read -r required_major required_minor required_patch <<< "${required#v}"

  ((
    current_major > required_major ||
    (current_major == required_major && current_minor > required_minor) ||
    (current_major == required_major && current_minor == required_minor && current_patch >= required_patch)
  ))
}

install_node_runtime() {
  local node_path npm_path node_version
  node_path="$(command -v node 2>/dev/null || true)"
  npm_path="$(command -v npm 2>/dev/null || true)"

  if [ -n "$node_path" ] && [ -n "$npm_path" ]; then
    echo "  ok    node ($node_path)"
    echo "  ok    npm  ($npm_path)"
  elif [ -n "$node_path" ] || [ -n "$npm_path" ]; then
    echo "Node.js installation is incomplete; refusing to install a second copy." >&2
    echo "node: ${node_path:-missing}" >&2
    echo "npm:  ${npm_path:-missing}" >&2
    return 1
  else
    echo "Installing Node.js and npm for Mason-managed language servers..."
    case "$(uname -s)" in
      Darwin)
        brew install node
        ;;
      Linux)
        if command -v apt-get >/dev/null 2>&1; then
          sudo apt-get install -y nodejs npm
        elif command -v dnf >/dev/null 2>&1; then
          sudo dnf install -y nodejs npm
        elif command -v pacman >/dev/null 2>&1; then
          sudo pacman -S --needed --noconfirm nodejs npm
        else
          echo "No supported package manager; install Node.js >= $NODE_MIN_VERSION and npm manually." >&2
          return 1
        fi
        ;;
      *)
        echo "Unsupported OS; install Node.js >= $NODE_MIN_VERSION and npm manually." >&2
        return 1
        ;;
    esac
  fi

  node_path="$(command -v node 2>/dev/null || true)"
  npm_path="$(command -v npm 2>/dev/null || true)"
  [ -n "$node_path" ] && [ -n "$npm_path" ] || {
    echo "Node.js/npm installation finished, but one or both commands are unavailable." >&2
    return 1
  }

  node_version="$(node --version)"
  if ! version_at_least "$node_version" "$NODE_MIN_VERSION"; then
    echo "Node.js $node_version is too old; Mason's TypeScript LSP needs >= $NODE_MIN_VERSION." >&2
    echo "Upgrade Node.js with the same manager that installed $node_path." >&2
    return 1
  fi
  echo "  ok    Node.js $node_version (minimum $NODE_MIN_VERSION)"
}

install_packages() {
  read -rp "Install tools (${PKGS[*]}), Node.js, uv, Neovim Python tooling and MesloLGS NF font? [y/N] " ans
  case "$ans" in
    [Yy]*) ;;
    *) echo "Skipping tool, Node.js, uv, Neovim Python tooling and font installation."; return ;;
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

  install_node_runtime
  install_uv
  install_nvim_python_host
  install_meslo_font
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
