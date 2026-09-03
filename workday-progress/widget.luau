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
  local barHeight = math.max(0, outHeight - (marginEnds * 2))

  local fillHeight = math.round(barHeight * percent)
  local emptyHeight = barHeight - fillHeight

  -- Smoothly transition from the theme's primary color to its secondary color
  local themeName = noctalia.getSetting("theme.builtin") or "Tokyo-Night"
  local palette = THEMES[themeName] or THEMES["Tokyo-Night"]
  local fillColor = interpolateColor(palette.primary, palette.secondary, percent)

  local children = {}
  if emptyHeight > 0 then
    table.insert(children, ui.box({
      width = thickness,
      height = emptyHeight,
      fill = "surface_variant/0.25",
    }))
  end

  if fillHeight > 0 then
    table.insert(children, ui.box({
      width = thickness,
      height = fillHeight,
      fill = fillColor,
      radius = 12,
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
    width = thickness,
    height = barHeight,
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
