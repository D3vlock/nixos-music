#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
USER_NAME="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"

echo "Repo: $REPO_DIR"
echo "User: $USER_NAME"
echo "Home: $USER_HOME"

mkdir -p "$USER_HOME/.config/SuperCollider"

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

git clone https://github.com/LazyVim/starter "$USER_HOME/.config/nvim"
rm -rf "$USER_HOME/.config/nvim/.git"

ln -sf "$REPO_DIR/supercollider/startup.scd" \
    "$USER_HOME/.config/SuperCollider/startup.scd"

ln -sf "$REPO_DIR/scripts/tidal.hs" \
    "$USER_HOME/tidal.hs"

ln -sf "$REPO_DIR/tmux/tmux.conf" \
    "$USER_HOME/.tmux.conf"

chown -h "$USER_NAME:$USER_NAME" "$USER_HOME/.config/SuperCollider/startup.scd" || true
chown -h "$USER_NAME:$USER_NAME" "$USER_HOME/tidal.hs" || true
chown -h "$USER_NAME:$USER_NAME" "$USER_HOME/.tmux.conf" || true

echo "sudo cp $REPO_DIR/configuration.nix /etc/nixos/configuration.nix"
sudo cp $REPO_DIR/configuration.nix /etc/nixos/configuration.nix
echo "sudo nixos-rebuild switch"
sudo nixos-rebuild switch

echo
echo "Installed:"
echo "  $USER_HOME/.config/SuperCollider/startup.scd -> $REPO_DIR/supercollider/startup.scd"
echo "  $USER_HOME/tidal.hs -> $REPO_DIR/tidal.hs"
echo
echo "Next:"
echo "  reboot"
echo "  sclang"
echo "  ghci -ghci-script ~/tidal.hs"
