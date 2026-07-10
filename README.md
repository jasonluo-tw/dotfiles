# dotfiles

Personal config for macOS and Linux — zsh + neovim. One script installs the
tools and symlinks everything into place.

## What's in here

| File | Links to | What it is |
|------|----------|------------|
| `home/.zshrc` | `~/.zshrc` | Shell config (Zim + Powerlevel10k), sources `~/.zsh_secrets` |
| `home/.zprofile` | `~/.zprofile` | Login-shell setup |
| `home/.zimrc` | `~/.zimrc` | Zim module list (bootstraps the shell) |
| `home/.p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k prompt theme |
| `home/.gitconfig` | `~/.gitconfig` | Git config |
| `home/.tmux.conf` | `~/.tmux.conf` | tmux config |
| `home/.vimrc` | `~/.vimrc` | Vim config (fallback editor) |
| `home/.inputrc` | `~/.inputrc` | readline key bindings |
| `config/nvim/` | `~/.config/nvim` | Neovim ([lazy.nvim](https://github.com/folke/lazy.nvim), pinned in `lazy-lock.json`) |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Claude Code global instructions |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code settings |
| `codex/config.toml` | `~/.codex/config.toml` | Codex settings (portable subset) |

`install.sh` links these; `.gitignore` keeps secrets and backups out of git.

**Not tracked** (on purpose): API keys and credentials live in `~/.zsh_secrets`
(chmod 600, git-ignored) and are sourced by `.zshrc`. The `~/.claude` and
`~/.codex` directories hold sessions/logs/auth, so only the individual config
files above are linked — never the whole directory.

## New machine setup

```sh
# 1. Clone
git clone https://github.com/jasonluo-tw/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Install tools + create all symlinks
./install.sh            # asks before installing packages; use --link-only to skip that
```

`install.sh` does two things:

1. **Installs required tools** — `neovim fzf bat tmux ripgrep` (asks first).
   - macOS → Homebrew (installs Homebrew itself if missing)
   - Linux → `apt` / `dnf` / `pacman` (whichever is present, via `sudo`; also installs `make`)
2. **Symlinks** every file above into place, backing up any existing file to
   `<file>.bak-<timestamp>` first. Safe to re-run.

Then:

```sh
# 3. Add your secrets (NOT in the repo)
cat > ~/.zsh_secrets <<'EOF'
export OPENROUTER_API_KEY="..."   # for CodeCompanion + Avante
export ANTHROPIC_API_KEY="..."
export OPENAI_API_KEY="..."
# ...any others you use
EOF
chmod 600 ~/.zsh_secrets

# 4. Start a new shell — Zim, Powerlevel10k and its modules bootstrap themselves
exec zsh

# 5. Open neovim — lazy.nvim bootstraps and installs all plugins
nvim
```

That's it. `zimfw`, Powerlevel10k, `lazy.nvim` and its plugins all self-install
on first launch, so they aren't part of `install.sh`.

## Notes

- **Neovim** requires ≥ 0.11. `:Lazy restore` reproduces the exact pinned plugin
  versions from `lazy-lock.json`.
- **AI plugins** (CodeCompanion, Avante) use OpenRouter — set `OPENROUTER_API_KEY`.
  Avante builds a small native lib via `make` on first install.
- **Portability**: machine-specific paths in `.zshrc` are existence-guarded, so
  the same file works on macOS and Linux without edits.
- **Updating the repo after changing a config**: since files are symlinked, edits
  to `~/.zshrc`, `~/.config/nvim/…`, etc. change the repo copies directly — just
  `git add`/`commit` in `~/dotfiles`.
