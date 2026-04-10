# MioIsland Plugin Template

[![Plugin Types](https://img.shields.io/badge/types-theme%20%7C%20buddy%20%7C%20sound-blue)](https://github.com/MioMioOS/mio-plugin-template)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Template repository for creating [MioIsland](https://github.com/MioMioOS) plugins. MioIsland is a macOS notch app for AI agent monitoring.

## Quick Start

1. **Fork** this repo (or click "Use this template")
2. Edit `plugin.json` with your plugin data
3. Add a `preview.png` screenshot
4. Validate: `./tools/validate.sh .`
5. Submit a PR to [MioMioOS/mio-plugin-registry](https://github.com/MioMioOS/mio-plugin-registry)

## Plugin Types

| Type | What it does | Key fields |
|------|-------------|------------|
| **Theme** | Custom color palette | `palette` with `bg`, `fg`, `secondaryFg` hex colors |
| **Buddy** | Animated pixel-art character | 13x11 grid, max 8 colors, 6 animation states |
| **Sound** | Notification & ambient audio | `.m4a`/`.mp3` files, max 5MB each, 20MB total |

## AI-Assisted Development

This repo is designed to work with AI coding assistants. Open it in **Claude Code** or **Codex** and the AI will read `CLAUDE.md` (or `AGENTS.md`) to understand the full plugin specification, including JSON schemas, pixel encoding format, and validation rules.

## Examples

- [`examples/theme-ocean-night`](examples/theme-ocean-night) - Dark ocean theme
- [`examples/buddy-robot`](examples/buddy-robot) - Pixel robot buddy
- [`examples/sound-notification`](examples/sound-notification) - Notification sound pack (JSON only; audio files not included in template)

## JSON Schemas

Formal JSON Schema files for editor autocompletion and validation:

- [`schemas/theme.schema.json`](schemas/theme.schema.json)
- [`schemas/buddy.schema.json`](schemas/buddy.schema.json)
- [`schemas/sound.schema.json`](schemas/sound.schema.json)

## Validation

```bash
chmod +x tools/validate.sh
./tools/validate.sh <plugin-directory>

# Examples:
./tools/validate.sh examples/theme-ocean-night
./tools/validate.sh examples/buddy-robot
```

## Project Structure

```
your-plugin/
  plugin.json      # Plugin manifest (required)
  preview.png      # Preview image (required)
  sounds/          # Audio files (sound plugins only)
```

## Documentation

- [CLAUDE.md](CLAUDE.md) - Full plugin specification (for AI assistants and humans)
- [AGENTS.md](AGENTS.md) - Same content as CLAUDE.md (for GitHub Codex compatibility)

## License

MIT
