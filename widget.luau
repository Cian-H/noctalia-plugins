--!strict
local calculate = require("./calculate.luau")

local function render()
  local stats = calculate.getStats()
  
  local color = "secondary"
  if stats.status == "completed" then
    color = "tertiary"
  elseif stats.status == "in_progress" then
    color = "primary"
  end

  local tooltip = {
    { key = noctalia.tr("panel.schedule"), value = stats.formattedSchedule },
    { key = noctalia.tr("panel.progress"), value = string.format("%.1f%%", stats.percent) },
    { key = noctalia.tr("panel.elapsed"), value = stats.formattedElapsed },
    { key = noctalia.tr("panel.remaining"), value = stats.formattedRemaining },
  }

  barWidget.setColor(color)

  barWidget.render(ui.progress({
    progress = stats.percent / 100.0,
    tooltip = tooltip,
    fill = true,
  }))
end

function update()
  noctalia.setUpdateInterval(30000)
  render()
end

function onConfigChanged()
  render()
end

render()
