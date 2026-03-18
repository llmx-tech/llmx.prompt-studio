#!/bin/bash
#
# LLMx Prompt Studio — macOS Installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/llmx-tech/llmx.prompt-studio/main/install.sh | bash
#   curl -fsSL ... | bash -s -- --version 1.0.0
#   ./install.sh --version 1.0.0
#
set -euo pipefail

APP_NAME="LLMx Prompt Studio"
GITHUB_REPO="llmx-tech/llmx.prompt-studio"
INSTALL_DIR="/Applications"
VERSION=""

# ── Helpers ──────────────────────────────────────────────────────────────

info()  { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
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
            echo "  --version, -v   Install a specific version (e.g. 1.0.0)"
            echo "  Without --version, installs the latest release."
            exit 0 ;;
        *) err "Unknown option: $1" ;;
    esac
done

# ── Preflight checks ────────────────────────────────────────────────────

[[ "$(uname -s)" == "Darwin" ]] || err "This installer only supports macOS."

ARCH="$(uname -m)"
case "$ARCH" in
    arm64)  ARCH_SUFFIX="aarch64" ;;
    x86_64) ARCH_SUFFIX="x86_64"  ;;
    *)      err "Unsupported architecture: $ARCH" ;;
esac

command -v curl   >/dev/null || err "curl is required but not found."
command -v hdiutil >/dev/null || err "hdiutil is required but not found."

# ── Resolve version & download URL ──────────────────────────────────────

if [ -z "$VERSION" ]; then
    info "Fetching latest release..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" \
        | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')
    [ -n "$VERSION" ] || err "Could not determine latest version. Pass --version explicitly."
fi

DMG_NAME="LLMx.Prompt.Studio_${VERSION}_${ARCH_SUFFIX}.dmg"
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/${DMG_NAME}"

info "Installing ${APP_NAME} v${VERSION} (${ARCH})..."

# ── Download ─────────────────────────────────────────────────────────────

TMPDIR_INSTALL="$(mktemp -d)"
DMG_PATH="${TMPDIR_INSTALL}/${DMG_NAME}"

info "Downloading ${DMG_NAME}..."
curl -fSL --progress-bar -o "$DMG_PATH" "$DOWNLOAD_URL" \
    || err "Download failed. Check that v${VERSION} exists at:\n  ${DOWNLOAD_URL}"

# ── Mount & install ──────────────────────────────────────────────────────

info "Mounting disk image..."
MOUNT_POINT="$(hdiutil attach "$DMG_PATH" -nobrowse -noautoopen | grep -o '/Volumes/.*$' | sed 's/[[:space:]]*$//')"

[ -d "${MOUNT_POINT}/${APP_NAME}.app" ] \
    || err "Could not find ${APP_NAME}.app in mounted DMG."

if [ -d "${INSTALL_DIR}/${APP_NAME}.app" ]; then
    info "Removing previous installation..."
    rm -rf "${INSTALL_DIR}/${APP_NAME}.app"
fi

info "Copying to ${INSTALL_DIR}/..."
cp -R "${MOUNT_POINT}/${APP_NAME}.app" "${INSTALL_DIR}/"

# ── Post-install ─────────────────────────────────────────────────────────

# Remove macOS quarantine flag (app is unsigned, Gatekeeper would block it)
xattr -rd com.apple.quarantine "${INSTALL_DIR}/${APP_NAME}.app" 2>/dev/null || true

ok "${APP_NAME} v${VERSION} installed successfully!"
echo ""
echo "  Open from Spotlight or run:"
echo "    open '/Applications/${APP_NAME}.app'"
echo ""
