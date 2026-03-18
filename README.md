# LLMx Prompt Studio

Desktop AI prompt management app. Design, test, and version prompts across OpenAI, Anthropic, Ollama, and 15+ LLM providers.

## Install

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/llmx-tech/llmx.prompt-studio/main/install.sh | bash
```

If macOS blocks the app ("unidentified developer"):
```bash
xattr -rd com.apple.quarantine "/Applications/LLMx Prompt Studio.app"
```

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/llmx-tech/llmx.prompt-studio/main/install.sh | bash
```

Installs an AppImage to `~/.local/bin/`. Works on Ubuntu, Fedora, Arch, and most other distros.

**Deb package** (Ubuntu/Debian) is also available on the [Releases](https://github.com/llmx-tech/llmx.prompt-studio/releases) page.

### Windows

```powershell
irm https://raw.githubusercontent.com/llmx-tech/llmx.prompt-studio/main/install.ps1 | iex
```

If SmartScreen blocks the installer, click **More info** then **Run anyway**.

### Specific version (all platforms)

```bash
# macOS / Linux
curl -fsSL .../install.sh | bash -s -- --version 0.1.0

# Windows
.\install.ps1 -Version 0.1.0
```

### Manual install

Download the right file from [Releases](https://github.com/llmx-tech/llmx.prompt-studio/releases):

| Platform | File |
|----------|------|
| macOS (Apple Silicon) | `.dmg` (aarch64) |
| macOS (Intel) | `.dmg` (x86_64) |
| Linux (universal) | `.AppImage` |
| Linux (Debian/Ubuntu) | `.deb` |
| Windows | `-setup.exe` |

## Uninstall

**macOS:**
```bash
rm -rf "/Applications/LLMx Prompt Studio.app"
rm -rf ~/Library/Application\ Support/de.llmx.promptstudio
```

**Linux:**
```bash
rm -f ~/.local/bin/LLMxPromptStudio.AppImage
rm -f ~/.local/share/applications/llmx-prompt-studio.desktop
rm -rf ~/.config/de.llmx.promptstudio
```

**Windows:** Uninstall from Settings > Apps, or run the uninstaller from the Start Menu.

## Requirements

| Platform | Requirement |
|----------|-------------|
| macOS | 10.15+ (Catalina or later), Apple Silicon or Intel |
| Linux | x86_64, GTK 3, WebKitGTK 4.1 |
| Windows | 10+, x86_64 or ARM64 |

## License

MIT
