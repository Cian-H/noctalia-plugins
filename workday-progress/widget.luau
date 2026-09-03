--!strict
local calculate = require("./calculate.luau")

local THEMES = {
  ["Ayu"] = { primary = "#39bae6", secondary = "#ffb454" },
  ["Catppuccin"] = { primary = "#89b4fa", secondary = "#f5c2e7" },
  ["Dracula"] = { primary = "#bd93f9", secondary = "#ff79c6" },
  ["Eldritch"] = { primary = "#04d1f9", secondary = "#a48cf2" },
  ["Gruvbox"] = { primary = "#83a598", secondary = "#d3869b" },
  ["Kanagawa"] = { primary = "#7e9cd8", secondary = "#957fb8" },
  ["Noctalia"] = { primary = "#85a5ff", secondary = "#b37feb" },
  ["Nord"] = { primary = "#88c0d0", secondary = "#b48ead" },
  ["Rosé Pine"] = { primary = "#9ccfd8", secondary = "#c4a7e7" },
  ["Tokyo-Night"] = { primary = "#7aa2f7", secondary = "#bb9af7" },
}

local function interpolateColor(c1: string, c2: string, t: number): string
  local r1 = tonumber(c1:sub(2, 3), 16) or 122
  local g1 = tonumber(c1:sub(4, 5), 16) or 162
  local b1 = tonumber(c1:sub(6, 7), 16) or 247

  local r2 = tonumber(c2:sub(2, 3), 16) or 187
  local g2 = tonumber(c2:sub(4, 5), 16) or 154
  local b2 = tonumber(c2:sub(6, 7), 16) or 247

  local r = math.round(r1 + (r2 - r1) * t)
  local g = math.round(g1 + (g2 - g1) * t)
  local b = math.round(b1 + (b2 - b1) * t)
  return string.format("#%02x%02x%02x", r, g, b)
end

local function render()
  local stats = calculate.getStats()
  local percent = math.clamp(stats.percent / 100.0, 0, 1)

  -- Get current output dimensions
  local outName = barWidget.outputName()
  local outHeight = 1080
  for _, o in ipairs(noctalia.outputs()) do
    if o.name == outName then
      outHeight = o.height
      break
    end
  end

  local thickness = noctalia.getSetting("bar.workday.thickness") or 64
  local marginEnds = noctalia.getSetting("bar.workday.margin_ends") or 52
  local barPadding = noctalia.getSetting("bar.workday.padding") or 4
  local barRadius = noctalia.getSetting("bar.workday.radius") or 12

  -- 4px uniform padding: trackWidth = 64 - 8 = 56
  local pad = 4
  local trackWidth = math.max(16, thickness - (pad * 2))

  -- Concentric corner radius: R_inner = R_outer - padding = 12 - 4 = 8
  local cornerRadius = math.max(2, barRadius - pad)

  -- Inset trackHeight by (barRadius * 2) so the rounded corners never overshoot the slot clip rect
  local verticalBuffer = barRadius * 2
  local trackHeight = math.max(16, outHeight - ((marginEnds + barPadding) * 2) - verticalBuffer)

  local fillHeight = math.round(trackHeight * percent)
  local emptyHeight = trackHeight - fillHeight

  -- Smoothly transition from the theme's primary color to its secondary color
  local themeName = noctalia.getSetting("theme.builtin") or "Tokyo-Night"
  local palette = THEMES[themeName] or THEMES["Tokyo-Night"]
  local fillColor = interpolateColor(palette.primary, palette.secondary, percent)

  local children = {}
  if emptyHeight > 0 then
    table.insert(children, ui.spacer({
      width = trackWidth,
      height = emptyHeight,
    }))
  end

  if fillHeight > 0 then
    table.insert(children, ui.box({
      width = trackWidth,
      height = fillHeight,
      fill = fillColor,
      radius = cornerRadius,
    }))
  end

  local tooltip = {
    { key = noctalia.tr("panel.schedule"), value = stats.formattedSchedule },
    { key = noctalia.tr("panel.progress"), value = string.format("%.1f%%", stats.percent) },
    { key = noctalia.tr("panel.elapsed"), value = stats.formattedElapsed },
    { key = noctalia.tr("panel.remaining"), value = stats.formattedRemaining },
  }
  barWidget.setTooltip(tooltip)

  barWidget.render(ui.column({
    width = trackWidth,
    height = trackHeight,
    fill = "surface_variant/0.3",
    radius = cornerRadius,
    gap = 0,
  }, children))
end

function update()
  noctalia.setUpdateInterval(30000)
  render()
end

function onConfigChanged()
  render()
end

render()
