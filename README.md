# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Установка

```sh
git clone https://github.com/CAMELNINJA/nvim-config ~/dotfiles/nvim-config
~/dotfiles/nvim-config/install.sh
```

Скрипт ставит зависимости (neovim, git, ripgrep, fd, fzf, lazygit, node, go,
tree-sitter-cli, Nerd Font), делает симлинк `~/.config/nvim` на репозиторий
(старый конфиг сохраняется в `.bak.*`) и синхронизирует плагины.
Флаги: `--no-deps`, `--no-plugins`.
