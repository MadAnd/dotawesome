-------------------------------------------------
-- CPU Widget for Awesome Window Manager
-- Shows the current CPU utilization (every core)
-- Based on:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/cpu-widget

-- @author Andriy Kmit
-- @copyright 2018 Andriy Kmit
-------------------------------------------------

local watch = require("awful.widget.watch")
local wibox = require("wibox")
local beautiful = require("beautiful")

local height_total = 4
--- Background color for progressbar showing the total CPU usage.
local bg_total = "#6c71c4"
--- Foreground color for progressbar showing the total CPU usage.
local fg_total = "#cb4b16"
local height_core = 2
--- Background color for progressbar showing the single core CPU usage.
local bg_core = "#859900"
--- Foreground color for progressbar showing the single core CPU usage.
local fg_core = "#dc322f"

-- Caches for values from previous iterations.
local total_prev = { }
local idle_prev = { }

------------------------------------------
-- Private utility functions
------------------------------------------

-- Synchronously read the command's output.
-- @return Command's output.
local function readcommand(command)
  local file = io.popen(command)
  local text = file:read('a')
  file:close()
  return text
end

--- Detect the number of available CPU cores.
-- @return Number of CPU cores.
local function detect_corenum()
  local corenum_cmd = [[sh -c 'cat /proc/stat | egrep 'cpu[0-9]+' | wc -l']]
  return math.tointeger(readcommand(corenum_cmd))
end

local function init_prev_vars(coresnum)
  for i = 1, coresnum do
    total_prev[i] = 0
    idle_prev[i] = 0
  end
end

local function create_progressbar(idx)
  -- Widget with idx=1 shows the total CPU usage.
  local bg = idx == 1 and bg_total or bg_core
  local fg = idx == 1 and fg_total or fg_core
  local height = idx == 1 and height_total or height_core

  return wibox.widget {
    max_value = 100,
    forced_height = height,
    background_color = bg,
    color = fg,
    widget = wibox.widget.progressbar
  }
end

local function wrap_progressbar(w)
  return wibox.widget {
    w,
    layout = wibox.container.margin,
    bottom = 1,
  }
end

local function wrap_final_widget(w)
  return wibox.widget {
    w,
    layout = wibox.container.margin,
    margins = 2,
  }
end

--- Parse a CPU-stat line form /proc/stat.
-- @param str Line from the /proc/stat.
-- @return user
-- @return nice
-- @return system
-- @return idle
-- @return iowait
-- @return irq
-- @return softirq
-- @return steal
-- @return guest
-- @return guest_nice
local function parse_cpustat_line(str)
  local cpuload_pattern = 'cpu%d*%s*(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)'
  return str:match(cpuload_pattern)
end

--- Compute the CPU usage percentage, relative to the given previous values.
-- @param str Line from the /proc/stat.
-- @param idle_prev Previous idle.
-- @param total_prev Previous total.
-- @return usage Usage percentage.
-- @return total New total.
-- @return idle New idle.
local function compute_usage(str, idle_prev, total_prev)
  local user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice = parse_cpustat_line(str)

  local total = user + nice + system + idle + iowait + irq + softirq + steal

  local diff_idle = idle - idle_prev
  local diff_total = total - total_prev
  local diff_usage = 100 * (1 - diff_idle / diff_total)

  return diff_usage, total, idle
end

------------------------------------------
-- Widget implementation
------------------------------------------

-- Initialize the vars for current CPU.
local coresnum = detect_corenum()
init_prev_vars(coresnum + 1)

-- Create progressbar widget for each CPU core and wrap them in layout.
local pbars = { }
local wrapped_pbars = { }
for i = 1, coresnum + 1 do
  local pbar = create_progressbar(i)
  pbars[i] = pbar
  wrapped_pbars[i] = wrap_progressbar(pbar)
end

-- Arrange all progressbars into vertical layout.
local l = wibox.layout.fixed.vertical()
for _, w in pairs(wrapped_pbars) do
  l:add(w)
end

-- Wrap them all in one more layout.
local cpuload_widget = wrap_final_widget(l)

local stats_cmd = [[sh -c "cat /proc/stat | egrep '^cpu'"]]
local update_interval = 2
watch(
  stats_cmd,
  update_interval,
  function(widget, stdout, stderr, exitreason, exitcode)
    local i = 1
    for s in stdout:gmatch("[^\r\n]+") do
      local usage, total, idle = compute_usage(s, idle_prev[i], total_prev[i])

      pbars[i]:set_value(usage)

      idle_prev[i] = idle
      total_prev[i] = total

      i = i + 1
    end
  end,
  cpuload_widget
)

return cpuload_widget
