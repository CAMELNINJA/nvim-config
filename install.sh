#!/usr/bin/env bash
# Устанавливает зависимости и линкует этот репозиторий в ~/.config/nvim.
# Использование: ./install.sh [--no-deps] [--no-plugins]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

install_deps=1
sync_plugins=1
for arg in "$@"; do
  case "$arg" in
    --no-deps) install_deps=0 ;;
    --no-plugins) sync_plugins=0 ;;
    -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
    *) echo "Неизвестный аргумент: $arg" >&2; exit 1 ;;
  esac
done

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

install_packages() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    have brew || { echo "Нужен Homebrew: https://brew.sh" >&2; exit 1; }
    brew install neovim git ripgrep fd fzf lazygit node go tree-sitter-cli
    brew install --cask font-jetbrains-mono-nerd-font || true
  elif have apt-get; then
    sudo apt-get update
    sudo apt-get install -y neovim git curl build-essential ripgrep fd-find fzf nodejs npm golang
    echo "lazygit и tree-sitter-cli в apt нет: https://github.com/jesseduffield/lazygit, npm i -g tree-sitter-cli"
  elif have pacman; then
    sudo pacman -S --needed --noconfirm neovim git curl base-devel ripgrep fd fzf lazygit nodejs npm go tree-sitter-cli
  elif have dnf; then
    sudo dnf install -y neovim git curl gcc make ripgrep fd-find fzf lazygit nodejs npm golang
  else
    echo "Неизвестный пакетный менеджер, поставь зависимости вручную (см. README)" >&2
    exit 1
  fi
}

link_config() {
  mkdir -p "$(dirname "$TARGET")"
  if [[ -L "$TARGET" && "$(readlink "$TARGET")" == "$REPO_DIR" ]]; then
    log "Симлинк уже настроен: $TARGET -> $REPO_DIR"
    return
  fi
  if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    backup="$TARGET.bak.$(date +%Y%m%d%H%M%S)"
    log "Существующий конфиг перенесён в $backup"
    mv "$TARGET" "$backup"
  fi
  ln -s "$REPO_DIR" "$TARGET"
  log "Создан симлинк: $TARGET -> $REPO_DIR"
}

if (( install_deps )); then
  log "Установка зависимостей"
  install_packages
fi

link_config

if (( sync_plugins )); then
  log "Установка плагинов (Lazy sync)"
  nvim --headless "+Lazy! sync" +qa
fi

log "Готово. Запускай: nvim"
