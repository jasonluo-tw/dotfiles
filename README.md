# dotfiles

My personal config files (macOS, zsh + neovim).

## Layout

```
home/     → symlinked into ~/            (.zshrc, .zprofile, .gitconfig, .tmux.conf, .vimrc, .inputrc)
config/   → symlinked into ~/.config/    (nvim)
claude/   → individual files into ~/.claude/   (CLAUDE.md, settings.json)
codex/    → individual files into ~/.codex/     (config.toml)
install.sh
```

Only the hand-picked config files under `claude/` and `codex/` are linked —
never the whole `~/.claude` / `~/.codex` dirs, which hold sessions, logs, and
auth tokens. Codex re-adds per-machine `[projects.*]` trust entries locally;
that churn is expected and not committed.

## Install

```sh
git clone https://github.com/jasonluo-tw/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` first installs the required tools (`neovim fzf bat tmux`), then
symlinks everything into place, backing up any existing file to
`<file>.bak-<timestamp>`. It asks before installing anything. Re-running is safe.
Use `./install.sh --link-only` to skip the package step and just refresh symlinks.

Package install is cross-platform: **macOS** via Homebrew (installed if missing),
**Linux** via apt / dnf / pacman (whichever is present, using `sudo`). Machine-
specific PATH entries in `.zshrc` are existence-guarded, so the same file works
on both.

Zim, powerlevel10k and lazy.nvim bootstrap themselves on first shell / nvim
launch, so they are not installed here.

## Secrets

API keys and credentials are **not** in this repo. They live in `~/.zsh_secrets`
(git-ignored, chmod 600), which `.zshrc` sources if present. Create it yourself
on a new machine:

```sh
cat > ~/.zsh_secrets <<'EOF'
export ANTHROPIC_API_KEY="..."
export OPENAI_API_KEY="..."
# etc.
EOF
chmod 600 ~/.zsh_secrets
```

## Neovim

Uses [lazy.nvim](https://github.com/folke/lazy.nvim) (auto-bootstraps on first
launch). Plugin versions are pinned in `config/nvim/lazy-lock.json` — run
`:Lazy restore` to reproduce them exactly. Requires neovim ≥ 0.11.
