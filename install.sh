#!/bin/bash
#
# LLMx Prompt Studio — macOS & Linux Installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/llmx-tech/llmx.prompt-studio/main/install.sh | bash
#   curl -fsSL ... | bash -s -- --version 0.1.0
#
set -euo pipefail

APP_NAME="LLMx Prompt Studio"
GITHUB_REPO="llmx-tech/llmx.prompt-studio"
VERSION=""

# ── Helpers ──────────────────────────────────────────────────────────────

info()  { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m==>\033[0m %s\n" "$*"; }
err()   { printf "\033[1;31mError:\033[0m %s\n" "$*" >&2; exit 1; }

cleanup() {
    if [ -n "${MOUNT_POINT:-}" ]; then
        hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true
    fi
    rm -rf "${TMPDIR_INSTALL:-}"
}
trap cleanup EXIT

# ── Parse args ───────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version|-v) VERSION="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: $0 [--version VERSION]"
            echo "  --version, -v   Install a specific version (e.g. 0.1.0)"
            echo "  Without --version, installs the latest release."
            exit 0 ;;
        *) err "Unknown option: $1" ;;
    esac
done

# ── Detect platform ─────────────────────────────────────────────────────

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$ARCH" in
    arm64|aarch64) ARCH_SUFFIX="aarch64" ;;
    x86_64)        ARCH_SUFFIX="x86_64"  ;;
    *)             err "Unsupported architecture: $ARCH" ;;
esac

command -v curl >/dev/null || err "curl is required but not found."

# ── Resolve version ─────────────────────────────────────────────────────

if [ -z "$VERSION" ]; then
    info "Fetching latest release..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" \
        | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')
    [ -n "$VERSION" ] || err "Could not determine latest version. Pass --version explicitly."
fi

info "Installing ${APP_NAME} v${VERSION} (${OS} ${ARCH})..."

TMPDIR_INSTALL="$(mktemp -d)"

# ── macOS ────────────────────────────────────────────────────────────────

install_macos() {
    command -v hdiutil >/dev/null || err "hdiutil is required but not found."

    local DMG_NAME="LLMx.Prompt.Studio_${VERSION}_${ARCH_SUFFIX}.dmg"
    local DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/${DMG_NAME}"
    local DMG_PATH="${TMPDIR_INSTALL}/${DMG_NAME}"
    local INSTALL_DIR="/Applications"

    info "Downloading ${DMG_NAME}..."
    curl -fSL --progress-bar -o "$DMG_PATH" "$DOWNLOAD_URL" \
        || err "Download failed. Check that v${VERSION} exists at: ${DOWNLOAD_URL}"

    info "Mounting disk image..."
    MOUNT_POINT="$(hdiutil attach "$DMG_PATH" -nobrowse -noautoopen \
        | grep -o '/Volumes/.*$' | sed 's/[[:space:]]*$//')"

    [ -d "${MOUNT_POINT}/${APP_NAME}.app" ] \
        || err "Could not find ${APP_NAME}.app in mounted DMG."

    if [ -d "${INSTALL_DIR}/${APP_NAME}.app" ]; then
        info "Removing previous installation..."
        rm -rf "${INSTALL_DIR}/${APP_NAME}.app"
    fi

    info "Copying to ${INSTALL_DIR}/..."
    cp -R "${MOUNT_POINT}/${APP_NAME}.app" "${INSTALL_DIR}/"

    xattr -rd com.apple.quarantine "${INSTALL_DIR}/${APP_NAME}.app" 2>/dev/null || true

    ok "${APP_NAME} v${VERSION} installed successfully!"
    echo ""
    echo "  Open from Spotlight or run:"
    echo "    open '/Applications/${APP_NAME}.app'"
    echo ""
}

# ── Linux ────────────────────────────────────────────────────────────────

install_linux() {
    # Tauri uses amd64 for x86_64 in AppImage naming
    local LINUX_ARCH="$ARCH_SUFFIX"
    [ "$LINUX_ARCH" = "x86_64" ] && LINUX_ARCH="amd64"

    local APPIMAGE_NAME="llmx-prompt-studio_${VERSION}_${LINUX_ARCH}.AppImage"
    local DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/${APPIMAGE_NAME}"
    local APPIMAGE_PATH="${TMPDIR_INSTALL}/${APPIMAGE_NAME}"

    local INSTALL_DIR="${HOME}/.local/bin"
    local INSTALLED_PATH="${INSTALL_DIR}/LLMxPromptStudio.AppImage"

    info "Downloading ${APPIMAGE_NAME}..."
    curl -fSL --progress-bar -o "$APPIMAGE_PATH" "$DOWNLOAD_URL" \
        || err "Download failed. Check that v${VERSION} exists at: ${DOWNLOAD_URL}"

    mkdir -p "$INSTALL_DIR"

    if [ -f "$INSTALLED_PATH" ]; then
        info "Removing previous installation..."
        rm -f "$INSTALLED_PATH"
    fi

    mv "$APPIMAGE_PATH" "$INSTALLED_PATH"
    chmod +x "$INSTALLED_PATH"

    # Create desktop entry
    local DESKTOP_DIR="${HOME}/.local/share/applications"
    mkdir -p "$DESKTOP_DIR"
    cat > "${DESKTOP_DIR}/llmx-prompt-studio.desktop" <<DESKTOP
[Desktop Entry]
Name=LLMx Prompt Studio
Exec=${INSTALLED_PATH}
Type=Application
Categories=Development;Utility;
Comment=AI Prompt Management Studio
Terminal=false
DESKTOP

    # Check if ~/.local/bin is in PATH
    case ":${PATH}:" in
        *":${INSTALL_DIR}:"*) ;;
        *)
            warn "${INSTALL_DIR} is not in your PATH."
            echo "  Add it to your shell profile:"
            echo "    echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
            echo ""
            ;;
    esac

    ok "${APP_NAME} v${VERSION} installed successfully!"
    echo ""
    echo "  Run from terminal:"
    echo "    LLMxPromptStudio.AppImage"
    echo ""
    echo "  Or find it in your application launcher."
    echo ""
}

# ── Dispatch ─────────────────────────────────────────────────────────────

case "$OS" in
    Darwin) install_macos ;;
    Linux)  install_linux ;;
    *)      err "Unsupported OS: $OS. Use install.ps1 for Windows." ;;
esac
