-- This information tells other players more about the mod
name = 'Place Statues'

description =
  'Client mod allow you to drop statues on the right point in other people server and do art with statues.\n Press R to enable Walking.\n Press  to walk to chosen point (Accuracy is 0.01 size of the statue).\n Press Z to drop statue to current place you standing.\n Press Ctr+P to change type of drop.\n Press Ctr+O to tweak drop by 0.5 grid.'
author = 'Tranoze'
version = '1.1.0'

api_version = 10

local opt_Empty = { { description = '', data = 0 } }
local function Title(title, hover)
  return {
    name = title,
    --label=title,
    hover = hover,
    options = opt_Empty,
    default = 0,
  }
end
local SEPARATOR = Title('')

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

configuration_options = {
  Title('Control setting'),
  {
    name = 'CENTERBUTTON',
    label = 'Center Button ',
    options = keys,
    default = 'KEY_P',
    hover = 'A key to set center point of most of the Statues placement.\n(Ctr + key to change placement type)',
  },
  {
    name = 'SECONDPOINTDO',
    label = 'Second Point Button',
    options = keys,
    default = 'KEY_O',
    hover = 'A key to set second point for line or some of the Statues placement.\n (Ctr + key to tweak placement by a bit)',
  },
  {
    name = 'WALKINGTOGGLE',
    label = 'Walking toggle Button',
    options = keys,
    default = 'KEY_R',
    hover = 'A key to show you where you going to drop the statue',
  },
}
all_clients_require_mod = false
client_only_mod = true
dont_starve_compatible = false
dst_compatible = true
reign_of_giants_compatible = false
shipwrecked_compatible = false

-- Can specify a custom icon for this mod!
icon_atlas = 'modicon.xml'
icon = 'modicon.tex'
