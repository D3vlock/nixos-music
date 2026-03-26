#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run as root (sudo)."
    exit 1
fi

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
USER_NAME="${SUDO_USER:?Run with sudo, not as root directly}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
USER_GROUP="$(id -gn "$USER_NAME")"

echo "Repo: $REPO_DIR"
echo "User: $USER_NAME"
echo "Home: $USER_HOME"

# --- Helpers ---

clone_or_pull() {
    local url="$1"
    local dest="$2"
    if [ -d "$dest/.git" ]; then
        echo "  [skip] $dest already exists, pulling instead"
        sudo -u "$USER_NAME" git -C "$dest" pull --ff-only
    else
        sudo -u "$USER_NAME" git clone "$url" "$dest"
    fi
}

safe_symlink() {
    local src="$1"
    local dest="$2"
    local owner="$3"
    if [ ! -e "$src" ]; then
        echo "  [warn] source does not exist: $src"
        return 1
    fi
    local destdir
    destdir="$(dirname "$dest")"
    mkdir -p "$destdir"
    chown "$owner:$USER_GROUP" "$destdir"
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        echo "  [skip] symlink already correct: $dest"
    else
        ln -sf "$src" "$dest"
        echo "  [link] $dest -> $src"
    fi
    chown -h "$owner:$USER_GROUP" "$dest" || true
}

# --- TPM ---
clone_or_pull \
    https://github.com/tmux-plugins/tpm \
    "$USER_HOME/.tmux/plugins/tpm"

# --- LazyVim (no .git — don't pull, just skip if present) ---
if [ -d "$USER_HOME/.config/nvim" ]; then
    echo "  [skip] nvim config already exists"
else
    sudo -u "$USER_NAME" git clone https://github.com/LazyVim/starter "$USER_HOME/.config/nvim"
    rm -rf "$USER_HOME/.config/nvim/.git"
fi

# --- Neovim plugins ---
safe_symlink \
    "$REPO_DIR/nvim/lua/tidal.lua" \
    "$USER_HOME/.config/nvim/lua/plugins/tidal.lua" \
    "$USER_NAME"

safe_symlink \
    "$REPO_DIR/nvim/lua/navigator.lua" \
    "$USER_HOME/.config/nvim/lua/plugins/navigator.lua" \
    "$USER_NAME"

safe_symlink \
    "$REPO_DIR/nvim/lua/luarocks.lua" \
    "$USER_HOME/.config/nvim/lua/plugins/luarocks.lua" \
    "$USER_NAME"

safe_symlink \
    "$REPO_DIR/nvim/lua/treesitter.lua" \
    "$USER_HOME/.config/nvim/lua/plugins/treesitter.lua" \
    "$USER_NAME"

safe_symlink \
    "$REPO_DIR/nvim/lua/snippets.lua" \
    "$USER_HOME/.config/nvim/lua/plugins/snippets.lua" \
    "$USER_NAME"

safe_symlink \
    "$REPO_DIR/nvim/lua/lsp.lua" \
    "$USER_HOME/.config/nvim/lua/plugins/lsp.lua" \
    "$USER_NAME"

# --- Symlinks ---
safe_symlink \
    "$REPO_DIR/supercollider/startup.scd" \
    "$USER_HOME/.config/SuperCollider/startup.scd" \
    "$USER_NAME"

safe_symlink \
    "$REPO_DIR/scripts/tidal.hs" \
    "$USER_HOME/tidal.hs" \
    "$USER_NAME"

safe_symlink \
    "$REPO_DIR/tmux/tmux.conf" \
    "$USER_HOME/.tmux.conf" \
    "$USER_NAME"

safe_symlink \
    "$REPO_DIR/scripts/music-session" \
    "$USER_HOME/music-session" \
    "$USER_NAME"

# --- NixOS config ---
if diff -q "$REPO_DIR/configuration.nix" /etc/nixos/music-configuration.nix &>/dev/null; then
    echo "  [skip] configuration.nix unchanged"
else
    echo "  [copy] configuration.nix -> /etc/nixos/music-configuration.nix"
    sudo cp "$REPO_DIR/configuration.nix" /etc/nixos/music-configuration.nix
    echo "  [nixos] rebuilding..."
    sudo nixos-rebuild switch
fi

echo
echo "Installed:"
echo "  $USER_HOME/.config/SuperCollider/startup.scd -> $REPO_DIR/supercollider/startup.scd"
echo "  $USER_HOME/tidal.hs -> $REPO_DIR/scripts/tidal.hs"
echo "  $USER_HOME/.tmux.conf -> $REPO_DIR/tmux/tmux.conf"
echo "  $USER_HOME/music-session -> $REPO_DIR/scripts/music-session"
echo
echo "Next:"
echo "  reboot"
echo "  music-session        # starts sclang in tmux"
echo "  nvim music.tidal     # :TidalLaunch to start tidal inside neovim"
