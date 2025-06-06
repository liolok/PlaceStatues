local function T(en, zh, zht) return ChooseTranslationTable({ en, zh = zh, zht = zht or zh }) end

name = T('Place Statues', '雕像摆放')
author = T('Tranoze, liolok', 'Tranoze、李皓奇')
local date = '2025-06-06'
version = date .. '' -- for revision in same day
description = T(
  [[Let you walk to a precise position, to place heavy item like statues or giant vegetables.
Supported layout: grid/circle/hexagon/line, press key to change.
󰀏 Usage:
1. Carry a heavy item or press key to enable precise walk manually
2. Use  to walk to the position you want
3. After some wiggling, character reports final distance to position
4. Use Shift +  to drop item at position
󰀖 Key bindings are adjustable in bottom of Settings > Controls page.]],
  [[精准走位到目标位置，方便摆放雕像或巨大作物等重物。
支持的布局：网格/圆形/六边形/直线，按键切换。
󰀏 用法：
1. 搬运重物，或者按键手动启用精准走位
2. 点击  开始走向你要去的位置
3. 扭来扭去之后角色报告离目标点的最终距离
4. 使用 Shift +  原地丢弃物品
󰀖 按键绑定可以在设置 > 控制页面下方实时调整。]]
) .. '\n󰀰 ' .. date -- Florid Postern（绚丽之门）

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
local key_disabled = { description = T('Disabled', '禁用'), data = 'KEY_DISABLED' }
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
    label = T('Auto Precise Walk', '自动精准走位'),
    hover = T('Enable precise walk when carrying heavy item.', '搬运重物时自动启用精准走位'),
    options = boolean,
    default = true,
  },
  {
    name = 'manual_key',
    label = T('Manual Precise Walk', '手动精准走位'),
    hover = T(
      'Toggle precise walk regardless whether carrying heavy item or not.',
      '手动切换精准走位，无视是否搬运重物。'
    ),
    options = keys,
    default = 'KEY_INSERT',
  },
  {
    name = 'layout_key',
    label = T('Change Placement Layout', '切换摆放布局'),
    hover = T(
      'Key to change layout through grid/circle/hexagon/line.',
      '按键切换网格/圆形/六边形/直线布局'
    ),
    options = keys,
    default = 'KEY_PAGEUP',
  },
  {
    name = 'align_target_key',
    label = T('Toggle Align Target', '切换对齐目标'),
    hover = T('Key to toggle align target between Wall and Turf.', '按键切换对齐到墙点/地皮'),
    options = keys,
    default = 'KEY_PAGEDOWN',
  },
  {
    name = 'first_point_key',
    label = T('Set Center/Start Point', '设置中心/起点'),
    hover = T(
      'Key to set cursor position as the center point of circle/hexagon.\n(Or the start point of line)',
      '将光标位置设为圆形/六边形的中心\n（或直线的起点）'
    ),
    options = keys,
    default = 'KEY_HOME',
  },
  {
    name = 'second_point_key',
    label = T('Set End Point', '设置终点'),
    hover = T('Key to set cursor position as the end point of line.', '将光标位置设为直线的终点'),
    options = keys,
    default = 'KEY_END',
  },
}
