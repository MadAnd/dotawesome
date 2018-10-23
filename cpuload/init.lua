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
local naughty = require("naughty")

-- Caches for values form previous iterations.
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

local function create_progressbar()
  return wibox.widget {
    max_value = 100,
    forced_height = 2,
    background_color = "#859900ff",
    color = "#dc322fff",
    widget = wibox.widget.progressbar
  }
end

local function wrap_progressbar(w)
  return wibox.widget {
    w,
    layout = wibox.container.margin,
    margins = 1,
  }
end

local function wrap_final_widget(w)
  return wibox.widget {
    w,
    layout = wibox.container.margin,
    margins = 2,
  }
end

--- Parse a single CPU-stat line form /proc/stats into 10 numbers.
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
  local cpuload_pattern = 'cpu%d+%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)'
  return str:match(cpuload_pattern)
end

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

-- Initialize the current CPU.
local coresnum = detect_corenum()
init_prev_vars(coresnum)

-- Create progressbar widget for each CPU core and wrap them in layout.
local pbars = { }
local wrapped_pbars = { }
for i = 1, coresnum do
  local pbar = create_progressbar()
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

local stats_cmd = [[sh -c "cat /proc/stat | egrep '^cpu[0-9]+'"]]
watch(
  stats_cmd,
  1,
  function(widget, stdout, stderr, exitreason, exitcode)
    local i = 1
    for s in stdout:gmatch("[^\r\n]+") do
      local usage, total, idle = compute_usage(s, idle_prev[i], total_prev[i])

      pbars[i]:set_value(usage)

      idle_prev[i] = idle
      total_prev[i] = total

      -- naughty.notify { text = tostring(i) }
      i = i + 1
    end
  end,
  cpuload_widget
)

return cpuload_widget
