# LLMx Prompt Studio

Desktop AI prompt management app. Design, test, and version prompts across OpenAI, Anthropic, Ollama, and 15+ LLM providers.

## Install

### macOS / Linux (one-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/llmx-tech/llmx.prompt-studio/main/install.sh | bash
```

- **macOS**: Downloads DMG, installs to `/Applications`, removes quarantine flag automatically.
- **Linux (Ubuntu/Debian)**: Detects your Ubuntu version (22.04 or 24.04) and installs the matching `.deb` package.

If macOS blocks the app ("unidentified developer"):
```bash
xattr -rd com.apple.quarantine "/Applications/LLMx Prompt Studio.app"
```

### Windows

```powershell
irm https://raw.githubusercontent.com/llmx-tech/llmx.prompt-studio/main/install.ps1 | iex
```

If SmartScreen blocks the installer, click **More info** then **Run anyway**.

### Specific version

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/llmx-tech/llmx.prompt-studio/main/install.sh | bash -s -- --version 0.1.3

# Windows
.\install.ps1 -Version 0.1.3
```

### Manual install

Download the right file from [Releases](https://github.com/llmx-tech/llmx.prompt-studio/releases):

| Platform | File |
|----------|------|
| macOS (Apple Silicon) | `.dmg` (aarch64) |
| macOS (Intel) | `.dmg` (x86_64) |
| Linux (Ubuntu 22.04) | `.deb` (ubuntu22) |
| Linux (Ubuntu 24.04) | `.deb` (ubuntu24) |
| Windows | `-setup.exe` |

## Uninstall

**macOS:**
```bash
rm -rf "/Applications/LLMx Prompt Studio.app"
rm -rf ~/Library/Application\ Support/de.llmx.promptstudio
```

**Linux:**
```bash
sudo dpkg -r llmx-prompt-studio
rm -rf ~/.config/de.llmx.promptstudio
```

**Windows:** Uninstall from Settings > Apps, or run the uninstaller from the Start Menu.

## Requirements

| Platform | Requirement |
|----------|-------------|
| macOS | 10.15+ (Catalina or later), Apple Silicon or Intel |
| Linux | x86_64, Ubuntu 22.04+ or Debian 12+, GTK 3, WebKitGTK 4.1 |
| Windows | 10+, x86_64 |

## License

MIT
