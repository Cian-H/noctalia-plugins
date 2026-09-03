--!strict
local calculate = require("./calculate.luau")

type ColorRgb = { r: number, g: number, b: number }
type ThemePair = { good: ColorRgb, bad: ColorRgb }

local function hexToRgb(hex: string): ColorRgb
  local clean = hex:gsub("#", "")
  return {
    r = tonumber(clean:sub(1, 2), 16) or 0,
    g = tonumber(clean:sub(3, 4), 16) or 0,
    b = tonumber(clean:sub(5, 6), 16) or 0,
  }
end

local function normalizeKey(key: string): string
  return key:lower():gsub("[^%a%d]", "")
end

-- Raw palette mapping each supported theme to canonical "good" (green) and "bad" (red) colors
local RAW_THEMES: { [string]: { good: string, bad: string } } = {
  ["tokyonight"] = { good = "#9ece6a", bad = "#f7768e" },
  ["catppuccin"] = { good = "#a6e3a1", bad = "#f38ba8" },
  ["catppuccinmocha"] = { good = "#a6e3a1", bad = "#f38ba8" },
  ["catppuccinmacchiato"] = { good = "#a6da95", bad = "#ed8796" },
  ["catppuccinfrappe"] = { good = "#a6d189", bad = "#e78284" },
  ["catppuccinlatte"] = { good = "#40a02b", bad = "#d20f39" },
  ["gruvbox"] = { good = "#b8bb26", bad = "#fb4934" },
  ["gruvboxdark"] = { good = "#b8bb26", bad = "#fb4934" },
  ["gruvboxlight"] = { good = "#79740e", bad = "#9d0006" },
  ["nord"] = { good = "#a3be8c", bad = "#bf616a" },
  ["dracula"] = { good = "#50fa7b", bad = "#ff5555" },
  ["ayu"] = { good = "#aad94c", bad = "#ea6c73" },
  ["eldritch"] = { good = "#37f499", bad = "#f16c75" },
  ["kanagawa"] = { good = "#76946a", bad = "#c34043" },
  ["noctalia"] = { good = "#9bfece", bad = "#fd4663" },
  ["solarized"] = { good = "#859900", bad = "#dc322f" },
  ["solarizeddark"] = { good = "#859900", bad = "#dc322f" },
  ["solarizedlight"] = { good = "#859900", bad = "#dc322f" },
  ["everforest"] = { good = "#a7c080", bad = "#e67e80" },
  ["everforestdark"] = { good = "#a7c080", bad = "#e67e80" },
  ["everforestlight"] = { good = "#8da101", bad = "#f85552" },
  ["rosepine"] = { good = "#31748f", bad = "#eb6f92" },
  ["rosepinemoon"] = { good = "#3e8fb0", bad = "#eb6f92" },
  ["rosepinedawn"] = { good = "#286983", bad = "#b4637a" },
}

-- Pre-parsed RGB pairs for zero-overhead runtime interpolation
local THEMES: { [string]: ThemePair } = {}
for key, pair in pairs(RAW_THEMES) do
  THEMES[key] = {
    good = hexToRgb(pair.good),
    bad = hexToRgb(pair.bad),
  }
end

local DEFAULT_PAIR: ThemePair = THEMES["tokyonight"]

local function interpolateColor(c1: ColorRgb, c2: ColorRgb, factor: number): string
  local r = math.round(c1.r + (c2.r - c1.r) * factor)
  local g = math.round(c1.g + (c2.g - c1.g) * factor)
  local b = math.round(c1.b + (c2.b - c1.b) * factor)
  return string.format("#%02x%02x%02x", r, g, b)
end

type LayoutGeometry = {
  isVertical: boolean,
  trackCross: number,
  trackMain: number,
  cornerRadius: number,
}

local function computeLayout(isVertical: boolean, outName: string?): LayoutGeometry
  local outputs = noctalia.outputs()
  local outDimension = 900
  if #outputs > 0 then
    outDimension = if isVertical then outputs[1].height else outputs[1].width
    if outName ~= nil then
      for _, o in ipairs(outputs) do
        if o.name == outName then
          outDimension = if isVertical then o.height else o.width
          break
        end
      end
    end
  end

  local thickness = (noctalia.getSetting("bar.workday.thickness") :: number?) or 64
  local marginEnds = (noctalia.getSetting("bar.workday.margin_ends") :: number?) or 4
  local barPadding = (noctalia.getSetting("bar.workday.padding") :: number?) or 4
  local barRadius = (noctalia.getSetting("bar.workday.radius") :: number?) or 20

  local configuredPad = (noctalia.getConfig("track_padding") :: number?) or 4
  local pad = math.clamp(configuredPad, 0, 16)
  local trackCross = math.max(16, thickness - (pad * 2))

  -- Concentric corner radius: R_inner = math.max(2, R_outer - padding)
  local cornerRadius = math.max(2, barRadius - pad)

  -- Check if an orthogonal bar (e.g. top bar for vertical workday bar) reserves space
  local reservedSpace = 0
  local defaultBarEnabled = noctalia.getSetting("bar.default.enabled")
  if defaultBarEnabled ~= false then
    local pos = (noctalia.getSetting("bar.default.position") :: string?) or "top"
    if isVertical and pos == "top" then
      local thick = (noctalia.getSetting("bar.default.thickness") :: number?) or 34
      local edge = (noctalia.getSetting("bar.default.margin_edge") :: number?) or 4
      reservedSpace = thick + edge
    end
  end

  local availableDimension = math.max(16, outDimension - reservedSpace)
  -- 2px buffer to guarantee float rounding never exceeds centerSlot clip rect
  local trackMain = math.max(16, availableDimension - ((marginEnds + barPadding) * 2) - 2)

  return {
    isVertical = isVertical,
    trackCross = trackCross,
    trackMain = trackMain,
    cornerRadius = cornerRadius,
  }
end

local function resolveIsVertical(): boolean
  if barWidget.isVertical() then
    return true
  end
  -- At script startup before Noctalia's first doLayout() pass,
  -- barWidget.isVertical() defaults to false in C++.
  -- Check if bar.workday is positioned on a vertical screen edge.
  local pos = noctalia.getSetting("bar.workday.position") :: string?
  if pos == "left" or pos == "right" then
    return true
  end
  return false
end

local function render()
  local stats = calculate.getStats()
  local percent = math.clamp(stats.percent / 100, 0, 1)

  local direction = (noctalia.getConfig("direction") :: string?) or "elapsed"
  local displayPercent = if direction == "remaining" then (1.0 - percent) else percent

  local isVertical = resolveIsVertical()
  local outName = barWidget.outputName()
  local layout = computeLayout(isVertical, outName)

  local fillSpan = math.round(layout.trackMain * displayPercent)
  local emptySpan = layout.trackMain - fillSpan

  -- Look up theme pair (good green -> bad red) or use solid theme accent
  local colorMode = (noctalia.getConfig("color_mode") :: string?) or "dynamic"
  local fillColor = "primary"
  if colorMode == "dynamic" then
    local themeName = (noctalia.getSetting("theme.builtin") :: string?) or "Tokyo-Night"
    local themePair = THEMES[normalizeKey(themeName)] or DEFAULT_PAIR
    fillColor = interpolateColor(themePair.good, themePair.bad, percent)
  end

  if isVertical then
    -- Vertical bar: fills bottom-to-top
    if displayPercent >= 1.0 then
      barWidget.render(ui.column({
        width = layout.trackCross,
        height = layout.trackMain,
        fill = fillColor,
        radius = layout.cornerRadius,
        gap = 0,
      }))
    else
      local children = {}
      if emptySpan > 0 then
        table.insert(children, ui.spacer({
          width = layout.trackCross,
          height = emptySpan,
        }))
      end
      if fillSpan > 0 then
        table.insert(children, ui.box({
          width = layout.trackCross,
          height = fillSpan,
          fill = fillColor,
          radius = layout.cornerRadius,
        }))
      end

      barWidget.render(ui.column({
        width = layout.trackCross,
        height = layout.trackMain,
        fill = "surface_variant/0.3",
        radius = layout.cornerRadius,
        gap = 0,
      }, children))
    end
  else
    -- Horizontal bar: fills left-to-right
    if displayPercent >= 1.0 then
      barWidget.render(ui.row({
        width = layout.trackMain,
        height = layout.trackCross,
        fill = fillColor,
        radius = layout.cornerRadius,
        gap = 0,
      }))
    else
      local children = {}
      if fillSpan > 0 then
        table.insert(children, ui.box({
          width = fillSpan,
          height = layout.trackCross,
          fill = fillColor,
          radius = layout.cornerRadius,
        }))
      end
      if emptySpan > 0 then
        table.insert(children, ui.spacer({
          width = emptySpan,
          height = layout.trackCross,
        }))
      end

      barWidget.render(ui.row({
        width = layout.trackMain,
        height = layout.trackCross,
        fill = "surface_variant/0.3",
        radius = layout.cornerRadius,
        gap = 0,
      }, children))
    end
  end

  local tooltip = {
    { key = noctalia.tr("panel.schedule"), value = stats.formattedSchedule },
    { key = noctalia.tr("panel.progress"), value = string.format("%.1f%%", stats.percent) },
    { key = noctalia.tr("panel.elapsed"), value = stats.formattedElapsed },
    { key = noctalia.tr("panel.remaining"), value = stats.formattedRemaining },
  }
  barWidget.setTooltip(tooltip)
end

function update()
  noctalia.setUpdateInterval(30000)
  render()
end

function onConfigChanged()
  render()
end

render()
