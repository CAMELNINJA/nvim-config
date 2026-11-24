#!/usr/bin/env bash
# Setup helpers for this Neovim config. Run via `task` (see Taskfile.yml).
# Usage: scripts/install.sh <deps|link|plugins>
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

install_deps() {
  log "Installing dependencies"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    have brew || { echo "Homebrew is required: https://brew.sh" >&2; exit 1; }
    brew install neovim git ripgrep fd fzf lazygit node go tree-sitter-cli
    brew install --cask font-jetbrains-mono-nerd-font || true
  elif have apt-get; then
    sudo apt-get update
    sudo apt-get install -y neovim git curl build-essential ripgrep fd-find fzf nodejs npm golang
    echo "lazygit and tree-sitter-cli are not in apt: https://github.com/jesseduffield/lazygit, npm i -g tree-sitter-cli"
  elif have pacman; then
    sudo pacman -S --needed --noconfirm neovim git curl base-devel ripgrep fd fzf lazygit nodejs npm go tree-sitter-cli
  elif have dnf; then
    sudo dnf install -y neovim git curl gcc make ripgrep fd-find fzf lazygit nodejs npm golang
  else
    echo "Unknown package manager, install the dependencies manually (see README)" >&2
    exit 1
  fi
}

link_config() {
  mkdir -p "$(dirname "$TARGET")"
  if [[ -L "$TARGET" && "$(readlink "$TARGET")" == "$REPO_DIR" ]]; then
    log "Symlink already set up: $TARGET -> $REPO_DIR"
    return
  fi
  if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    backup="$TARGET.bak.$(date +%Y%m%d%H%M%S)"
    log "Existing config moved to $backup"
    mv "$TARGET" "$backup"
  fi
  ln -s "$REPO_DIR" "$TARGET"
  log "Created symlink: $TARGET -> $REPO_DIR"
}

sync_plugins() {
  log "Installing plugins (Lazy sync)"
  nvim --headless "+Lazy! sync" +qa
}

case "${1:-}" in
  deps) install_deps ;;
  link) link_config ;;
  plugins) sync_plugins ;;
  *) echo "Usage: $0 <deps|link|plugins>" >&2; exit 1 ;;
esac
