#!/usr/bin/env bash
# Installs the `share` command to ~/.local/bin (no sudo needed).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
TARGET="$INSTALL_DIR/share"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tinyshare"
TEMPLATE_TARGET="$DATA_DIR/template.yaml"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${GREEN}▶${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC}  $*"; }

# ── Install ───────────────────────────────────────────────────────────────────

mkdir -p "$INSTALL_DIR" "$DATA_DIR"
cp "$SCRIPT_DIR/share" "$TARGET"
chmod +x "$TARGET"
cp "$SCRIPT_DIR/template.yaml" "$TEMPLATE_TARGET"
info "Installed: $TARGET"
info "Installed: $TEMPLATE_TARGET"

# ── PATH check ────────────────────────────────────────────────────────────────

if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    echo ""
    warn "$INSTALL_DIR is not in your PATH."
    echo ""

    # Detect shell and suggest the right rc file
    SHELL_NAME=$(basename "${SHELL:-bash}")
    case "$SHELL_NAME" in
        zsh)  RC_FILE="$HOME/.zshrc" ;;
        bash) RC_FILE="$HOME/.bashrc" ;;
        fish) RC_FILE="$HOME/.config/fish/config.fish" ;;
        *)    RC_FILE="~/.profile" ;;
    esac

    if [[ "$SHELL_NAME" == "fish" ]]; then
        echo "  Add this to $RC_FILE:"
        echo ""
        echo "    fish_add_path $INSTALL_DIR"
    else
        echo "  Add this to $RC_FILE:"
        echo ""
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi

    echo ""
    echo "  Then restart your shell or run:"
    echo ""
    if [[ "$SHELL_NAME" == "fish" ]]; then
        echo "    source $RC_FILE"
    else
        echo "    source $RC_FILE"
    fi
    echo ""
else
    echo ""
    echo -e "  ${BOLD}share${NC} is ready. Next step:"
    echo ""
    echo "    share setup"
    echo ""
fi
