--!strict

export type WorkdayStats = {
  startHour: number,
  startMinute: number,
  endHour: number,
  endMinute: number,
  progress: number,
  percent: number,
  status: "not_started" | "in_progress" | "completed",
  totalMinutes: number,
  elapsedMinutes: number,
  remainingMinutes: number,
  formattedSchedule: string,
  formattedElapsed: string,
  formattedRemaining: string,
  statusText: string,
}

local calculate = {}

function calculate.getStats(): WorkdayStats
  local rawStartH = (noctalia.getConfig("start_hour") :: number?) or 9
  local rawStartM = (noctalia.getConfig("start_minute") :: number?) or 0
  local rawEndH = (noctalia.getConfig("end_hour") :: number?) or 17
  local rawEndM = (noctalia.getConfig("end_minute") :: number?) or 0

  -- Sanitize inputs to valid clock boundaries
  local startH = math.clamp(rawStartH, 0, 23)
  local startM = math.clamp(rawStartM, 0, 59)
  local endH = math.clamp(rawEndH, 0, 23)
  local endM = math.clamp(rawEndM, 0, 59)

  local now = os.time()
  local d = os.date("*t", now)
  local utcDate = os.date("!*t", now)
  -- In Luau, os.time(table) assumes the table is in UTC.
  -- Calculate timezone offset so local schedule hours convert to correct epoch seconds.
  local tzOffset = os.time(d) - os.time(utcDate)

  local startSec = os.time({
    year = d.year,
    month = d.month,
    day = d.day,
    hour = startH,
    min = startM,
    sec = 0,
  }) - tzOffset

  local endSec = os.time({
    year = d.year,
    month = d.month,
    day = d.day,
    hour = endH,
    min = endM,
    sec = 0,
  }) - tzOffset

  -- Handle overnight shifts that cross midnight
  if endSec <= startSec then
    if now < endSec then
      startSec = startSec - 86400
    else
      endSec = endSec + 86400
    end
  end

  local totalSec = math.max(1, endSec - startSec)
  local formattedSchedule = string.format("%02d:%02d – %02d:%02d", startH, startM, endH, endM)

  local workDays = (noctalia.getConfig("work_days") :: string?) or "weekdays"
  local isWeekend = (d.wday == 1 or d.wday == 7) -- Sunday = 1, Saturday = 7
  if workDays == "weekdays" and isWeekend then
    local totalMinutes = math.floor(totalSec / 60)
    return {
      startHour = startH,
      startMinute = startM,
      endHour = endH,
      endMinute = endM,
      progress = 0.0,
      percent = 0.0,
      status = "not_started",
      totalMinutes = totalMinutes,
      elapsedMinutes = 0,
      remainingMinutes = totalMinutes,
      formattedSchedule = formattedSchedule,
      formattedElapsed = "0h 00m",
      formattedRemaining = string.format("%dh %02dm", math.floor(totalMinutes / 60), totalMinutes % 60),
      statusText = noctalia.tr("status.weekend"),
    }
  end
  local progress = 0.0
  local status: "not_started" | "in_progress" | "completed" = "in_progress"
  local elapsedSec = 0
  local remainingSec = 0

  if now <= startSec then
    progress = 0.0
    status = "not_started"
    elapsedSec = 0
    remainingSec = totalSec
  elseif now >= endSec then
    progress = 1.0
    status = "completed"
    elapsedSec = totalSec
    remainingSec = 0
  else
    progress = math.clamp((now - startSec) / totalSec, 0.0, 1.0)
    status = "in_progress"
    elapsedSec = now - startSec
    remainingSec = endSec - now
  end

  local totalMinutes = math.floor(totalSec / 60)
  local elapsedMinutes = math.floor(elapsedSec / 60)
  local remainingMinutes = math.floor(remainingSec / 60)

  local elapsedH = math.floor(elapsedMinutes / 60)
  local elapsedM = elapsedMinutes % 60

  local remainingH = math.floor(remainingMinutes / 60)
  local remainingM = remainingMinutes % 60

  local formattedElapsed = string.format("%dh %02dm", elapsedH, elapsedM)
  local formattedRemaining = string.format("%dh %02dm", remainingH, remainingM)

  local statusText = ""
  if status == "not_started" then
    statusText = noctalia.tr("status.not_started")
  elseif status == "completed" then
    statusText = noctalia.tr("status.completed")
  else
    statusText = noctalia.tr("status.in_progress")
  end

  return {
    startHour = startH,
    startMinute = startM,
    endHour = endH,
    endMinute = endM,
    progress = progress,
    percent = progress * 100,
    status = status,
    totalMinutes = totalMinutes,
    elapsedMinutes = elapsedMinutes,
    remainingMinutes = remainingMinutes,
    formattedSchedule = formattedSchedule,
    formattedElapsed = formattedElapsed,
    formattedRemaining = formattedRemaining,
    statusText = statusText,
  }
end

return calculate
