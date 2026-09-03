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
  local startH = (noctalia.getConfig("start_hour") :: number?) or 9
  local startM = (noctalia.getConfig("start_minute") :: number?) or 0
  local endH = (noctalia.getConfig("end_hour") :: number?) or 17
  local endM = (noctalia.getConfig("end_minute") :: number?) or 0

  local now = os.time()
  local d = os.date("*t", now)

  local startSec = os.time({
    year = d.year,
    month = d.month,
    day = d.day,
    hour = startH,
    min = startM,
    sec = 0,
  })

  local endSec = os.time({
    year = d.year,
    month = d.month,
    day = d.day,
    hour = endH,
    min = endM,
    sec = 0,
  })

  local totalSec = math.max(1, endSec - startSec)
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

  local formattedSchedule = string.format("%02d:%02d – %02d:%02d", startH, startM, endH, endM)
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
