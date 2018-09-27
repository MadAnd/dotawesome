---------------------------------------------------------------------------
-- @author Andriy Kmit' &lt;dev@madand.net&gt;
-- @copyright 2016 Andriy Kmit'
-- @module multimedia
---------------------------------------------------------------------------

local awful = require("awful")
local naughty = require("naughty")

local multimedia = {}
local current_notification_id = 0
-- This will be toggled by initial call to multimedia.volume_mute(false).
local muted = true

multimedia.volume_font = '20'
multimedia.playback_font = '12'
multimedia.icon_size = 48
multimedia.icon_dir = awful.util.getdir("config") .. "/multimedia/icons/"
multimedia.icons = {
  volume_changed="audio-volume-high.svg",
  volume_muted="audio-volume-muted.svg",
  playback_start="media-playback-start.svg",
  playback_stop="media-playback-stop.svg",
  playback_paused="media-playback-pause.svg",
}

multimedia.sound_system = "alsa"
multimedia.cmd = {
  alsa = {
    set_volume = "amixer set Master %s &>/dev/null",
    volume_up = "%s%%+",
    volume_down = "%s%%-",
    volume_get = "amixer get Master | egrep -o '[[:digit:]]+%'",
    mute = "amixer set Master %s",
    mute_on = "mute",
    mute_off = "unmute",
  },
  pulse = {
    set_volume = "pactl set-sink-volume @DEFAULT_SINK@ %s",
    volume_up = "+%s%%",
    volume_down = "-%s%%",
    volume_get = "echo $(pactl list sinks | grep 'Volume: front-left:' | awk '{print $5}')",
    mute = "pactl set-sink-mute @DEFAULT_SINK@ %s",
    mute_on = "1",
    mute_off = "0",
  },
}

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--- Volume control functions
-- @section

local function volume_notify(text, icon)
  current_notification_id = naughty.notify({
      text = text,
      font = multimedia.volume_font,
      icon = multimedia.icon_dir .. icon,
      icon_size = multimedia.icon_size,
      timeout = 2,
      replaces_id = current_notification_id
  }).id
end

function multimedia.volume_change(percent_delta)
  local cmd_config = multimedia.cmd[multimedia.sound_system]
  local value
  if percent_delta > 0 then
    value = cmd_config.volume_up:format(percent_delta)
  else
    value = cmd_config.volume_down:format(math.abs(percent_delta))
  end

  local cmd = cmd_config.set_volume:format(value) ..
    " && " .. cmd_config.volume_get
  volume_notify(trim(awful.util.pread(cmd)), multimedia.icons.volume_changed)
end

--- Mute or un-mute sound.
-- @tparam int value Mute sound if true, toggle if nil, otherwise - unmute.
function multimedia.volume_mute(value)
  if value ~= muted then
    local cmd_config = multimedia.cmd[multimedia.sound_system]
    local cmd, icon

    muted = not muted
    if muted then
      icon = multimedia.icons.volume_muted
      cmd = cmd_config.mute:format(cmd_config.mute_on)
    else
      icon = multimedia.icons.volume_changed
      cmd = cmd_config.mute:format(cmd_config.mute_off)
    end

    awful.util.spawn_with_shell(cmd)
    volume_notify(nil, icon)
  end
end

--- Playback control functions.
-- @section

function multimedia.playback_toggle()
  awful.util.spawn_with_shell("mpc toggle")
end

function multimedia.playback_stop()
  awful.util.spawn_with_shell("mpc stop")
end

function multimedia.playback_next()
  awful.util.spawn_with_shell("mpc next")
end

function multimedia.playback_prev()
  awful.util.spawn_with_shell("mpc prev")
end

return multimedia
