# LLMx Prompt Studio

Desktop AI prompt management app. Design, test, and version prompts across OpenAI, Anthropic, Ollama, and 15+ LLM providers.

## Install (macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/llmx-tech/llmx.prompt-studio/main/install.sh | bash
```

### Specific version

```bash
curl -fsSL https://raw.githubusercontent.com/llmx-tech/llmx.prompt-studio/main/install.sh | bash -s -- --version 1.0.0
```

### Manual install

1. Download the `.dmg` from [Releases](https://github.com/llmx-tech/llmx.prompt-studio/releases)
2. Open the DMG and drag **LLMx Prompt Studio** to Applications
3. If macOS blocks the app, run:
   ```bash
   xattr -rd com.apple.quarantine "/Applications/LLMx Prompt Studio.app"
   ```

## Uninstall

```bash
rm -rf "/Applications/LLMx Prompt Studio.app"
rm -rf ~/Library/Application\ Support/de.llmx.promptstudio
```

## Requirements

- macOS 10.15+ (Catalina or later)
- Apple Silicon (M1/M2/M3/M4) or Intel x86_64

## License

MIT
