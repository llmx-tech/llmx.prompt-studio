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

detect_distro_label() {
    # Returns ubuntu22, ubuntu24, or empty string
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "${ID:-}" in
            ubuntu|pop|linuxmint|elementary|zorin)
                case "${VERSION_ID:-}" in
                    24.*|25.*) echo "ubuntu24"; return ;;
                    22.*|23.*) echo "ubuntu22"; return ;;
                esac
                ;;
            debian)
                case "${VERSION_ID:-}" in
                    12|13) echo "ubuntu22"; return ;;  # bookworm/trixie ~ glibc 2.36
                    *) ;;
                esac
                ;;
        esac
    fi
    # Fallback: check glibc version
    if command -v ldd >/dev/null 2>&1; then
        local GLIBC_VER
        GLIBC_VER="$(ldd --version 2>&1 | head -1 | grep -oP '\d+\.\d+$' || echo "")"
        if [ -n "$GLIBC_VER" ]; then
            local MINOR="${GLIBC_VER##*.}"
            if [ "$MINOR" -ge 38 ] 2>/dev/null; then
                echo "ubuntu24"; return
            elif [ "$MINOR" -ge 35 ] 2>/dev/null; then
                echo "ubuntu22"; return
            fi
        fi
    fi
    echo ""
}

install_linux_deb() {
    local DISTRO_LABEL="$1"
    local DEB_NAME="LLMx.Prompt.Studio_${VERSION}_amd64-${DISTRO_LABEL}.deb"
    local DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/${DEB_NAME}"
    local DEB_PATH="${TMPDIR_INSTALL}/llmx.deb"

    info "Downloading ${DEB_NAME}..."
    if ! curl -fSL --progress-bar -o "$DEB_PATH" "$DOWNLOAD_URL"; then
        warn "No ${DISTRO_LABEL} .deb found, falling back to AppImage..."
        install_linux_appimage
        return
    fi

    info "Installing runtime dependencies..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq libwebkit2gtk-4.1-0 libgtk-3-0 libayatana-appindicator3-1 2>/dev/null || true

    info "Installing .deb package..."
    sudo dpkg -i "$DEB_PATH" || sudo apt-get install -f -y

    ok "${APP_NAME} v${VERSION} installed successfully!"
    echo ""
    echo "  Run: llmx-prompt-studio"
    echo "  Or find it in your application launcher."
    echo ""
}

install_linux_appimage() {
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

install_linux() {
    case "$ARCH" in
        x86_64|amd64) ;; # supported
        *) err "Unsupported Linux architecture: $ARCH. Only x86_64 is currently supported." ;;
    esac

    local DISTRO_LABEL
    DISTRO_LABEL="$(detect_distro_label)"

    if [ -n "$DISTRO_LABEL" ] && command -v apt-get >/dev/null 2>&1; then
        info "Detected compatible Debian/Ubuntu system (${DISTRO_LABEL})"
        install_linux_deb "$DISTRO_LABEL"
    else
        info "Using AppImage (universal Linux package)"
        install_linux_appimage
    fi
}

# ── Dispatch ─────────────────────────────────────────────────────────────

case "$OS" in
    Darwin) install_macos ;;
    Linux)  install_linux ;;
    *)      err "Unsupported OS: $OS. Use install.ps1 for Windows." ;;
esac
