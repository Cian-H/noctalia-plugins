--!strict

local calculate = require("./calculate")

local function render()
  local stats = calculate.getStats()

  local displayFormat = (noctalia.getConfig("display_format") :: string?) or "compact"
  local showGlyph = noctalia.getConfig("show_glyph")
  if showGlyph == nil then
    showGlyph = true
  end
  local glyph = (noctalia.getConfig("glyph") :: string?) or "briefcase"

  if showGlyph then
    barWidget.setGlyph(glyph)
  end

  local text = ""
  if displayFormat == "percent" then
    text = string.format("%.1f%%", stats.percent)
  elseif displayFormat == "time_remaining" then
    if stats.status == "not_started" then
      text = stats.statusText
    elseif stats.status == "completed" then
      text = stats.statusText
    else
      text = string.format("%s left", stats.formattedRemaining)
    end
  elseif displayFormat == "full" then
    if stats.status == "not_started" then
      text = string.format("0%% • %s", stats.statusText)
    elseif stats.status == "completed" then
      text = string.format("100%% • %s", stats.statusText)
    else
      text = string.format("%.0f%% • %s left", stats.percent, stats.formattedRemaining)
    end
  else -- "compact"
    text = string.format("%.0f%%", stats.percent)
  end

  barWidget.setText(text)

  if stats.status == "completed" then
    barWidget.setGlyphColor("tertiary", nil)
  elseif stats.status == "in_progress" then
    barWidget.setGlyphColor("primary", nil)
  else
    barWidget.setGlyphColor("secondary", nil)
  end

  barWidget.setTooltip({
    { key = noctalia.tr("panel.schedule"), value = stats.formattedSchedule },
    { key = noctalia.tr("panel.progress"), value = string.format("%.1f%%", stats.percent) },
    { key = noctalia.tr("panel.elapsed"), value = stats.formattedElapsed },
    { key = noctalia.tr("panel.remaining"), value = stats.formattedRemaining },
  })

  barWidget.setVisible(true)
end

function update()
  -- Refresh every 30 seconds
  noctalia.setUpdateInterval(30000)
  render()
end

function onConfigChanged()
  render()
end

-- Initial render on load
render()

