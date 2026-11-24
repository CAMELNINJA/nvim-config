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

## Rex integration

`lua/rex/init.lua` integrates Neovim with the [Rex](https://www.superlogical.com/rex)
terminal through the `rex` CLI. It does nothing outside Rex.

| Key / command                        | Action                                                          |
| ------------------------------------ | --------------------------------------------------------------- |
| `<C-h/j/k/l>`                        | Move between Neovim windows, then on to the neighbouring Rex pane |
| `<leader>rr` / `:RexRun [cmd]`       | Run a command in the runner pane (a shell pane below the editor) |
| `<leader>rl` / `:RexRerun`           | Rerun the last command                                          |
| `<leader>rt`                         | Run tests for the filetype (`go test ./...`, `cargo test`, ...)  |
| `<leader>rs` / `:RexSend`            | Send the current line or visual selection to the runner         |
| `<leader>rq` / `:RexQuickfix`        | Load the runner's output into the quickfix list                 |
| `<leader>rf` / `:RexFocus`           | Focus the runner pane                                           |
| `<leader>rk` / `:RexClose`           | Close the runner pane                                           |
| `<leader>rv`, `<leader>rh` / `:RexSplit [dir] [file]` | Open the file in a new Rex pane with its own nvim |
