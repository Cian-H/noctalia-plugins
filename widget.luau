--!strict
local calculate = require("./calculate.luau")

local function hslToHex(h, s, l)
    local r, g, b
    if s == 0 then
        r, g, b = l, l, l
    else
        local function hue2rgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1/6 then return p + (q - p) * 6 * t end
            if t < 1/2 then return q end
            if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
            return p
        end
        local q = 0
        if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
        local p = 2 * l - q
        r = hue2rgb(p, q, h + 1/3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1/3)
    end
    return string.format("#%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function render()
  local stats = calculate.getStats()
  local percent = stats.percent / 100.0

  local outName = barWidget.outputName()
  local outHeight = 1080
  for _, o in ipairs(noctalia.outputs()) do
    if o.name == outName then
      outHeight = o.height
      break
    end
  end
  
  -- Determine widget thickness and margins from the bar it's placed in
  local thickness = noctalia.getSetting("bar.workday.thickness") or 64
  local marginEnds = noctalia.getSetting("bar.workday.margin_ends") or 52
  local barHeight = outHeight - (marginEnds * 2)

  -- Use percentages instead of absolute pixels so multiple instances with different dimensions
  -- don't fight over the same SVG's aspect ratio!
  local fillPercent = percent * 100
  local emptyPercent = (1.0 - percent) * 100

  -- Color logic from v4: Green to Red
  local colorCode = hslToHex((1.0 - percent) * 0.33, 0.85, 0.60)

  local dataDir = noctalia.pluginDataDir()
  if not dataDir then return end
  local svgPath = dataDir .. "/progress.svg"
  
  local svg = string.format([[
<svg width="100%%" height="100%%" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="100%%" height="100%%" fill="#1e1e1e" />
  <rect x="0" y="%.2f%%" width="100%%" height="%.2f%%" fill="%s" rx="8" />
</svg>
]], emptyPercent, fillPercent, colorCode)
  
  noctalia.writeFile(svgPath, svg)
  
  local tooltip = {
    { key = noctalia.tr("panel.schedule"), value = stats.formattedSchedule },
    { key = noctalia.tr("panel.progress"), value = string.format("%.1f%%", stats.percent) },
    { key = noctalia.tr("panel.elapsed"), value = stats.formattedElapsed },
    { key = noctalia.tr("panel.remaining"), value = stats.formattedRemaining },
  }
  barWidget.setTooltip(tooltip)
  
  -- Pass the dimensions explicitly to barWidget.setImage so it sets the layout size
  barWidget.setImage(svgPath, true, thickness, barHeight)
end

function update()
  noctalia.setUpdateInterval(30000)
  render()
end

function onConfigChanged()
  render()
end

render()
