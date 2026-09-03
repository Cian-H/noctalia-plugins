--!strict

local calculate = require("./calculate")

local function render()
  local stats = calculate.getStats()

  local statusColor = "primary"
  if stats.status == "completed" then
    statusColor = "tertiary"
  elseif stats.status == "not_started" then
    statusColor = "secondary"
  end

  panel.render(
    ui.column({ gap = 12, padding = 16 }, {
      -- Header
      ui.row({ align = "center", justify = "space-between" }, {
        ui.row({ align = "center", gap = 8 }, {
          ui.glyph({ name = "briefcase", size = 20, color = statusColor }),
          ui.label({
            text = noctalia.tr("panel.title"),
            fontWeight = "bold",
            fontSize = 16,
          }),
        }),
        ui.box({
          fill = statusColor .. "/0.2",
          radius = 6,
          paddingH = 8,
          paddingV = 4,
        }, {
          ui.label({
            text = stats.statusText,
            color = statusColor,
            fontWeight = "bold",
            fontSize = 12,
          }),
        }),
      }),

      -- Progress bar & percentage
      ui.column({ gap = 6 }, {
        ui.row({ justify = "space-between", align = "center" }, {
          ui.label({
            text = noctalia.tr("panel.progress"),
            color = "on_surface_variant",
            fontSize = 13,
          }),
          ui.label({
            text = string.format("%.1f%%", stats.percent),
            fontWeight = "bold",
            fontSize = 14,
            color = statusColor,
          }),
        }),
        ui.progress({
          value = stats.progress,
          color = statusColor,
        }),
      }),

      -- Details Box
      ui.box({
        fill = "surface_variant",
        radius = 8,
        padding = 12,
      }, {
        ui.column({ gap = 8 }, {
          ui.row({ justify = "space-between" }, {
            ui.label({ text = noctalia.tr("panel.schedule"), color = "on_surface_variant", fontSize = 13 }),
            ui.label({ text = stats.formattedSchedule, fontWeight = "bold", fontSize = 13 }),
          }),
          ui.row({ justify = "space-between" }, {
            ui.label({ text = noctalia.tr("panel.elapsed"), color = "on_surface_variant", fontSize = 13 }),
            ui.label({ text = stats.formattedElapsed, fontWeight = "bold", fontSize = 13 }),
          }),
          ui.row({ justify = "space-between" }, {
            ui.label({ text = noctalia.tr("panel.remaining"), color = "on_surface_variant", fontSize = 13 }),
            ui.label({ text = stats.formattedRemaining, fontWeight = "bold", fontSize = 13 }),
          }),
        }),
      }),
    })
  )
end

function onOpen()
  render()
end

function update()
  noctalia.setUpdateInterval(30000)
  render()
end

function onConfigChanged()
  render()
end
