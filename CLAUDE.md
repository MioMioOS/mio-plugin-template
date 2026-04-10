# MioIsland Plugin Development Guide

> This file is the definitive reference for AI assistants (Claude Code, Codex, etc.) to generate valid MioIsland plugins.

## What is MioIsland?

MioIsland is a **macOS notch app** for AI agent monitoring. It lives in the MacBook notch area and shows real-time status of AI coding agents (Claude Code, Cursor, etc.). Plugins customize the app's appearance and behavior.

## Plugin Types

There are exactly **3 plugin types**: `theme`, `buddy`, and `sound`.

---

## Common Fields (plugin.json)

Every plugin has a `plugin.json` at its root with these required fields:

```json
{
  "type": "theme" | "buddy" | "sound",
  "id": "kebab-case-id",
  "name": "Human Readable Name",
  "version": "1.0.0",
  "author": {
    "name": "Author Name",
    "url": "https://example.com",
    "github": "username"
  },
  "price": 0,
  "description": "Short description of the plugin",
  "tags": ["tag1", "tag2"],
  "preview": "preview.png"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `type` | string | yes | One of: `theme`, `buddy`, `sound` |
| `id` | string | yes | Unique, kebab-case (e.g., `ocean-night`) |
| `name` | string | yes | Display name |
| `version` | string | yes | Semver (e.g., `1.0.0`) |
| `author` | object | yes | Must have `name`; `url` and `github` are optional |
| `price` | integer | yes | Price in cents USD. `0` = free |
| `description` | string | yes | One-line description |
| `tags` | string[] | yes | At least one tag |
| `preview` | string | yes | Path to preview image (PNG recommended, relative to plugin dir) |

---

## 1. Theme Plugin

A theme changes the color palette of MioIsland.

### Schema

```json
{
  "type": "theme",
  "id": "string (kebab-case)",
  "name": "string",
  "version": "string (semver)",
  "author": {
    "name": "string",
    "url": "string (optional)",
    "github": "string (optional)"
  },
  "price": "integer (cents USD, 0 = free)",
  "description": "string",
  "tags": ["string"],
  "preview": "string (path to preview image)",
  "palette": {
    "bg": "string (hex color, e.g. #0A1628)",
    "fg": "string (hex color, e.g. #E0E8F0)",
    "secondaryFg": "string (hex color, e.g. #6B7D94)"
  }
}
```

### Rules

- **All colors must be valid 6-digit hex** (e.g., `#FF00AA`). No shorthand, no named colors.
- **Contrast ratio between `bg` and `fg` must be >= 4.5:1** (WCAG AA). Use a contrast checker.
- `secondaryFg` is for muted text/icons; no strict contrast requirement but should be legible.

### Example

```json
{
  "type": "theme",
  "id": "ocean-night",
  "name": "Ocean Night",
  "version": "1.0.0",
  "author": { "name": "MioIsland Team" },
  "price": 0,
  "palette": {
    "bg": "#0A1628",
    "fg": "#E0E8F0",
    "secondaryFg": "#6B7D94"
  },
  "preview": "preview.png",
  "description": "Deep ocean dark theme",
  "tags": ["dark", "blue"]
}
```

---

## 2. Buddy Plugin

A buddy is an animated pixel-art character that lives in the notch area and reacts to agent states.

### Schema

```json
{
  "type": "buddy",
  "id": "string (kebab-case)",
  "name": "string",
  "version": "string (semver)",
  "author": {
    "name": "string",
    "url": "string (optional)",
    "github": "string (optional)"
  },
  "price": "integer (cents USD, 0 = free)",
  "description": "string",
  "tags": ["string"],
  "preview": "string (path to preview image)",
  "grid": {
    "width": 13,
    "height": 11,
    "cellSize": 4
  },
  "palette": [
    "string (hex color)"
  ],
  "animations": {
    "idle": { "frames": ["string (base64)"], "fps": "number" },
    "working": { "frames": ["string (base64)"], "fps": "number" },
    "needsYou": { "frames": ["string (base64)"], "fps": "number" },
    "thinking": { "frames": ["string (base64)"], "fps": "number" },
    "error": { "frames": ["string (base64)"], "fps": "number" },
    "done": { "frames": ["string (base64)"], "fps": "number" }
  }
}
```

### Grid

- Fixed **13 columns x 11 rows**
- `cellSize`: 4 (each pixel renders as 4x4 screen points)
- Total canvas: 52 x 44 points

### Palette

- Array of hex colors, **max 8 colors**
- Index 0 is always **transparent** (not listed in palette array)
- Palette entries map to indices 1-8
- Example: `["#1A1A2E", "#E94560"]` means index 1 = `#1A1A2E`, index 2 = `#E94560`

### Pixel Data (frames)

Each frame is a **base64-encoded 4-bit indexed bitmap**:

1. Lay out pixels left-to-right, top-to-bottom (13 x 11 = 143 pixels)
2. Each pixel is a 4-bit nibble (0 = transparent, 1-8 = palette index)
3. Pack two pixels per byte: **high nibble first**, then low nibble
4. 143 pixels = 72 bytes (last byte has one padding nibble, set to 0)
5. Base64-encode the 72 bytes

### Animation States (all 6 required)

| State | When shown |
|-------|-----------|
| `idle` | Agent is idle, no active session |
| `working` | Agent is running, executing code |
| `needsYou` | Agent needs user approval/input |
| `thinking` | Agent is thinking/planning |
| `error` | Agent encountered an error |
| `done` | Agent completed the task |

Each state has:
- `frames`: array of base64 strings (at least 1 frame; use 2+ for animation)
- `fps`: number (frames per second, typically 1-4)

### Example

```json
{
  "type": "buddy",
  "id": "robot",
  "name": "Robot",
  "version": "1.0.0",
  "author": { "name": "MioIsland Team" },
  "price": 0,
  "description": "A friendly pixel robot buddy",
  "tags": ["robot", "pixel"],
  "preview": "preview.png",
  "grid": { "width": 13, "height": 11, "cellSize": 4 },
  "palette": ["#2C3E50", "#3498DB"],
  "animations": {
    "idle": {
      "frames": [
        "AAARERAAAAASERIQAAABERERAAAAARERAAAAERERERAAASERESEAABEREREQAAAREREQAAABEAARAAAAEQABEAAAERAAERAA",
        "AAARERAAAAASERIQAAABERERAAAAARERAAABEREREREAECERESAQAAEREREAAAAREREQAAABEAARAAAAEQABEAAAERAAERAA"
      ],
      "fps": 2
    },
    "working": {
      "frames": ["AAARERAAAAASERIQAAABERERAAAAARERAAAAERERERAAASERESEAABEREREQAAAREREQAAABEAARAAAAEQABEAAAERAAERAA"],
      "fps": 2
    },
    "needsYou": {
      "frames": ["AAARERAAAAASERIQAAABERERAAAAARERAAABEREREREAECERESAQAAEREREAAAAREREQAAABEAARAAAAEQABEAAAERAAERAA"],
      "fps": 1
    },
    "thinking": {
      "frames": ["AAARERAAAAASERIQAAABERERAAAAARERAAAAERERERAAASERESEAABEREREQAAAREREQAAABEAARAAAAEQABEAAAERAAERAA"],
      "fps": 1
    },
    "error": {
      "frames": ["AAARERAAAAASERIQAAABERERAAAAARERAAAAERERERAAASERESEAABEREREQAAAREREQAAABEAARAAAAEQABEAAAERAAERAA"],
      "fps": 1
    },
    "done": {
      "frames": ["AAARERAAAAASERIQAAABERERAAAAARERAAABEREREREAECERESAQAAEREREAAAAREREQAAABEAARAAAAEQABEAAAERAAERAA"],
      "fps": 1
    }
  }
}
```

---

## 3. Sound Plugin

A sound plugin provides audio for notifications and ambient effects.

### Schema

```json
{
  "type": "sound",
  "id": "string (kebab-case)",
  "name": "string",
  "version": "string (semver)",
  "author": {
    "name": "string",
    "url": "string (optional)",
    "github": "string (optional)"
  },
  "price": "integer (cents USD, 0 = free)",
  "description": "string",
  "tags": ["string"],
  "preview": "string (path to preview image)",
  "category": "music" | "notification" | "ambient",
  "sounds": {
    "session_start": "string (path to audio file, optional)",
    "needs_approval": "string (path to audio file, optional)",
    "session_complete": "string (path to audio file, optional)",
    "error": "string (path to audio file, optional)"
  }
}
```

### Rules

- **Audio formats**: `.m4a` or `.mp3` only
- **Categories**: `music`, `notification`, or `ambient`
- **Single file max**: 5 MB
- **Total pack max**: 20 MB
- **Notification events** (all optional, but include at least one):
  - `session_start` — Agent session begins
  - `needs_approval` — Agent needs user approval
  - `session_complete` — Agent finished successfully
  - `error` — Agent encountered an error
- Sound file paths are relative to the plugin directory

### Example

```json
{
  "type": "sound",
  "id": "chime-pack",
  "name": "Chime Pack",
  "version": "1.0.0",
  "author": { "name": "MioIsland Team" },
  "price": 0,
  "description": "Gentle chime notification sounds",
  "tags": ["chime", "notification", "gentle"],
  "preview": "preview.png",
  "category": "notification",
  "sounds": {
    "session_start": "sounds/start.m4a",
    "needs_approval": "sounds/approval.m4a",
    "session_complete": "sounds/complete.m4a",
    "error": "sounds/error.m4a"
  }
}
```

---

## Validation

Run the included validation script:

```bash
./tools/validate.sh <plugin-directory>
```

This checks:
- `plugin.json` exists and is valid JSON
- Required fields are present
- Preview file exists
- Type-specific validation (hex colors for themes, animation states for buddies)

## Submitting a Plugin

1. Fork this template repo
2. Create your plugin in the root directory (your `plugin.json` at the top level)
3. Validate with `./tools/validate.sh .`
4. Submit a PR to [MioMioOS/mio-plugin-registry](https://github.com/MioMioOS/mio-plugin-registry)

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| Invalid hex color | Using shorthand (`#FFF`) or named colors | Always use 6-digit hex: `#FFFFFF` |
| Low contrast ratio | `bg`/`fg` too similar | Use a contrast checker; aim for >= 4.5:1 |
| Missing animation state | Buddy missing one of the 6 required states | Include all: `idle`, `working`, `needsYou`, `thinking`, `error`, `done` |
| Wrong pixel data length | Base64 doesn't decode to 72 bytes | 13x11 grid = 143 nibbles = 72 bytes |
| Palette too large | More than 8 colors in buddy palette | Use at most 8 indexed colors |
| Audio too large | Sound file over 5 MB | Compress or trim the audio |
| Pack too large | Total sound files over 20 MB | Reduce number or size of sound files |
| Invalid version | Not semver | Use format `MAJOR.MINOR.PATCH` (e.g., `1.0.0`) |
| Missing preview | No preview image | Add a `preview.png` to your plugin directory |
