name = 'Place Statues'
description =
  'Client mod allow you to drop statues on the right point in other people server and do art with statues.\n Press R to enable Walking.\n Press  to walk to chosen point (Accuracy is 0.01 size of the statue).\n Press Z to drop statue to current place you standing.\n Press Ctr+P to change type of drop.\n Press Ctr+O to tweak drop by 0.5 grid.'
author = 'Tranoze, liolok'
version = '1.1.0'
api_version = 10
dst_compatible = true
client_only_mod = true
icon_atlas = 'modicon.xml'
icon = 'modicon.tex'

local keyboard = { -- from STRINGS.UI.CONTROLSSCREEN.INPUTS[1] of strings.lua, need to match constants.lua too.
  { 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12', 'Print', 'ScrolLock', 'Pause' },
  { '1', '2', '3', '4', '5', '6', '7', '8', '9', '0' },
  { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M' },
  { 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z' },
  { 'Escape', 'Tab', 'CapsLock', 'LShift', 'LCtrl', 'LSuper', 'LAlt' },
  { 'Space', 'RAlt', 'RSuper', 'RCtrl', 'RShift', 'Enter', 'Backspace' },
  { 'Tilde', 'Minus', 'Equals', 'LeftBracket', 'RightBracket', 'Backslash', 'Semicolon', 'Period', 'Slash' }, -- punctuation
  { 'Up', 'Down', 'Left', 'Right', 'Insert', 'Delete', 'Home', 'End', 'PageUp', 'PageDown' }, -- navigation
}
local numpad = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'Period', 'Divide', 'Multiply', 'Minus', 'Plus' }
local mouse = { '\238\132\130', '\238\132\131', '\238\132\132' } -- Middle Mouse Button, Mouse Button 4 and 5
local key_disabled = { description = 'Disabled', data = 'KEY_DISABLED' }
keys = { key_disabled }
for i = 1, #mouse do
  keys[#keys + 1] = { description = mouse[i], data = mouse[i] }
end
for i = 1, #keyboard do
  for j = 1, #keyboard[i] do
    local key = keyboard[i][j]
    keys[#keys + 1] = { description = key, data = 'KEY_' .. key:upper() }
  end
  keys[#keys + 1] = key_disabled
end
for i = 1, #numpad do
  local key = numpad[i]
  keys[#keys + 1] = { description = 'Numpad ' .. key, data = 'KEY_KP_' .. key:upper() }
end

local boolean = { { description = 'No', data = false }, { description = 'Yes', data = true } }

configuration_options = {
  {
    name = 'auto_precise_walk',
    label = 'Auto Precise Walk',
    hover = 'Enable precise walk when carrying heavy item.',
    options = boolean,
    default = true,
  },
  {
    name = 'precise_walk_key',
    label = 'Manual Precise Walk',
    hover = 'Key to let you walk to a precise position, whether carrying heavy item or not.',
    options = keys,
    default = 'KEY_DISABLED',
  },
  {
    name = 'placement_type_key',
    label = 'Change Placement Type',
    hover = 'Key to change placement type through grid/circle/hexagon/line.',
    options = keys,
    default = 'KEY_DISABLED',
  },
  {
    name = 'align_target_key',
    label = 'Toggle Align Target',
    hover = 'Key to toggle align target between Wall and Turf.',
    options = keys,
    default = 'KEY_DISABLED',
  },
  {
    name = 'first_point_key',
    label = 'Set Center/Start Point',
    hover = 'Key to set cursor position as the center point of circle/hexagon.\n(Or the start point of line)',
    options = keys,
    default = 'KEY_DISABLED',
  },
  {
    name = 'second_point_key',
    label = 'Set End Point',
    hover = 'Key to set cursor position as the end point of line.',
    options = keys,
    default = 'KEY_DISABLED',
  },
}
