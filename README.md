# Noctalia Plugins

A collection of custom plugins for the [Noctalia](https://github.com/noctalia-dev/noctalia) Wayland desktop shell.

## Available Plugins

| Plugin | ID | Description |
|---|---|---|
| **[Workday Progress](./workday-progress)** | `cian-h/workday-progress` | Tracks and visualizes progress throughout your workday on your bar and in a details popup. |

---

## Adding this Source to Noctalia

### In `config.toml`

Add this repository as a git source in `~/.config/noctalia/config.toml`:

```toml
[[plugins.source]]
name     = "cian-h"
kind     = "git"
location = "https://github.com/Cian-H/noctalia-plugins"
enabled  = true

[plugins]
enabled = [
  "cian-h/workday-progress",
]
```

*(For local development, you can set `kind = "path"` and point `location` to your local clone path).*

### Via IPC CLI

```bash
noctalia msg plugins source add cian-h git https://github.com/Cian-H/noctalia-plugins
noctalia msg plugins enable cian-h/workday-progress
```

### Via Settings GUI

1. Open **Settings → Plugins**.
2. Click **Add source**.
3. Select **Git** and enter `https://github.com/Cian-H/noctalia-plugins` with name `cian-h`.
4. Toggle on the plugins you want to enable.
