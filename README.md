# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Installation

Requires [Task](https://taskfile.dev) (`brew install go-task`).

```sh
git clone https://github.com/CAMELNINJA/nvim-config ~/go/src/myprojects/nvim-config
cd ~/go/src/myprojects/nvim-config
task install
```

`task install` runs three steps, each also available on its own:

| Task           | What it does                                                                                      |
| -------------- | ------------------------------------------------------------------------------------------------- |
| `task deps`    | Installs neovim, git, ripgrep, fd, fzf, lazygit, node, go, tree-sitter-cli and a Nerd Font         |
| `task link`    | Symlinks the repo to `~/.config/nvim` (an existing config is backed up to `nvim.bak.<timestamp>`) |
| `task plugins` | Syncs plugins with `Lazy sync`                                                                    |
