# dotfiles

My personal config files (macOS, zsh + neovim).

## Layout

```
home/     → symlinked into ~/            (.zshrc, .zprofile, .gitconfig, .tmux.conf, .vimrc, .inputrc)
config/   → symlinked into ~/.config/    (nvim)
install.sh
```

## Install

```sh
git clone https://github.com/jasonluo-tw/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` symlinks everything into place and backs up any existing file to
`<file>.bak-<timestamp>` first. Re-running it is safe.

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
