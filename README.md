# Workday Progress (Noctalia v5 Plugin)

A sleek, customizable plugin for [Noctalia](https://github.com/noctalia-dev/noctalia) v5 that tracks and visualizes your progress throughout the workday.

## Features

- **Bar Widget**: Displays live workday progress directly on your bar (compact percentage, detailed percent, time remaining, or full mode).
- **Interactive Details Panel**: Click the widget (or invoke via IPC) to see an overview of your schedule, percentage complete, visual progress bar, elapsed time, and time remaining.
- **Native Settings GUI**: Configure start and end hours/minutes directly inside Noctalia's **Settings → Plugins** configuration menu.
- **Theme Integrated**: Colors dynamically adapt to your active Noctalia color palette (`primary`, `tertiary`, `secondary`).

---

## Installation & Configuration

### Enabling the Plugin

Add the plugin to your `~/.config/noctalia/config.toml`:

```toml
[plugins]
enabled = [
  "cian-h/workday-progress",
]

[[plugins.source]]
name     = "workday-progress"
kind     = "path"
location = "~/Storage/Programming/Personal_Projects/workday-progress"
enabled  = true
```

### Adding the Bar Widget

Add `cian-h/workday-progress:progress` to one of your bar lanes (e.g. `start`, `center`, or `end`):

```toml
[bar.default.lanes]
end = [
  "cian-h/workday-progress:progress",
  "battery",
  "volume",
  "clock",
]
```

Or configure custom widget settings:

```toml
[widget.my-workday]
type = "cian-h/workday-progress:progress"
display_format = "compact" # "compact" | "percent" | "time_remaining" | "full"
glyph = "briefcase"
show_glyph = true
```

### IPC Commands

Toggle the summary panel from your window manager (Hyprland / Niri) or terminal:

```bash
noctalia msg panel-toggle cian-h/workday-progress:summary
```

---

## Development

This repository includes a [`devenv`](https://devenv.sh/) environment equipped with the Luau development toolchain:

```bash
devenv shell
```

Tools included:
- `luau`
- `luau-lsp`
- `taplo` (TOML formatter/linter)
- `stylua` (Luau code formatter)
