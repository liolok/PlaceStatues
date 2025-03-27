local G = GLOBAL

--------------------------------------------------------------------------------
-- precise walk to target position

local WALK_DELAY = 0.8
local walk_task = nil
local target_x, target_z = nil, nil
local player_previous_position = nil
local should_stop_walk = false
local step_distance = nil

local function GetPlayerPosition()
  local x, _, z = G.ThePlayer.Transform:GetWorldPosition()
  return x, z
end

local function GetDistances(x, z)
  local player_x, player_z = GetPlayerPosition()
  local dx = x - player_x
  local dz = z - player_z
  local distance = math.sqrt(dx ^ 2 + dz ^ 2) -- the distance between player and given position
  return distance, dx, dz
end

local function Tip(message) return G.ThePlayer.components.talker:Say(message) end

local function ReportFinalDistance() Tip(tostring(GetDistances(target_x, target_z))) end

local function WalkTo(x, z)
  local act = G.BufferedAction(G.ThePlayer, nil, G.ACTIONS.WALKTO, nil, G.Vector3(x, 0, z))
  if G.ThePlayer.components.playercontroller:CanLocomote() then -- forest-only world
    act.preview_cb = function() G.SendRPCToServer(G.RPC.LeftClick, act.action.code, x, z, nil, true) end
    G.ThePlayer.components.playercontroller:DoAction(act)
  else -- forest-cave world
    G.SendRPCToServer(G.RPC.LeftClick, act.action.code, x, z, nil, nil, nil, act.action.canforce)
  end
end

local DELTA_RATIO = 1 / 6
local function BabyStepTo(x, z)
  local player_x, player_z = GetPlayerPosition()
  if player_x == x and player_z == z then return end -- already at destination
  local distance, dx, dz = GetDistances(x, z)
  local delta = G.Vector3(dx, 0, dz) * DELTA_RATIO / distance
  WalkTo(player_x + delta.x, player_z + delta.z)
end

local function GetRoutePosition(player_radius)
  local distance, dx, dz = GetDistances(target_x, target_z)
  if distance == 0 then return nil end

  -- length from player to its projection of target circle
  local length = (player_radius ^ 2 - step_distance ^ 2 + distance ^ 2) / (2 * distance)
  if player_radius < length then return nil end

  local player_x, player_z = GetPlayerPosition()
  local projection_x = player_x + dx * length / distance
  local projection_z = player_z + dz * length / distance

  local offset = math.sqrt(player_radius ^ 2 - length ^ 2) -- perpendicular/height offset
  local intersection_x = projection_x + dz * offset / distance
  local intersection_z = projection_z - dx * offset / distance

  return G.Vector3(intersection_x, 0, intersection_z)
end

local function StopPreciseWalk()
  should_stop_walk = false
  step_distance = nil
  if walk_task then
    walk_task:Cancel()
    walk_task = nil
  end
end

local function IsPlayerBusy()
  local is_idle = G.ThePlayer:HasTag('idle')
  local is_doing_or_working = G.ThePlayer.components.playercontroller:IsDoingOrWorking()
  return not is_idle or is_doing_or_working
end

local function StartPreciseWalk(player)
  if IsPlayerBusy() then
    walk_task = player:DoTaskInTime(WALK_DELAY, StartPreciseWalk)
    return
  end
  if step_distance == nil then
    if player_previous_position == nil then
      local x, z = GetPlayerPosition()
      player_previous_position = G.Vector3(x, 0, z)
      BabyStepTo(target_x, target_z)
    else
      local d = GetDistances(player_previous_position.x, player_previous_position.z)
      if d > 0.01 then step_distance = d end
      player_previous_position = nil
    end
  else
    if GetDistances(target_x, target_z) > 0.3 then
      WalkTo(target_x, target_z)
    else
      if should_stop_walk then
        BabyStepTo(target_x, target_z)
        StopPreciseWalk()
        player:DoTaskInTime(WALK_DELAY, ReportFinalDistance)
        return
      else
        local relative_distance = math.floor(GetDistances(target_x, target_z) / step_distance)
        local is_too_close = relative_distance < 2
        local player_radius = is_too_close and step_distance or (relative_distance * step_distance)
        local route_position = GetRoutePosition(player_radius)
        if route_position then
          BabyStepTo(route_position.x, route_position.z)
          should_stop_walk = is_too_close
        else
          StopPreciseWalk()
          player:DoTaskInTime(WALK_DELAY, ReportFinalDistance)
          return
        end
      end
    end
  end
  walk_task = player:DoTaskInTime(WALK_DELAY, StartPreciseWalk)
end

--------------------------------------------------------------------------------
-- key bindings

modimport('keybind')

local AUTO_ENABLE = GetModConfigData('auto_precise_walk') -- did user configure "Auto Precise Walk" to true?
local LAYOUT = { 'grid', 'circle', 'hexagon', 'line' }
local S = {
  grid = '[Place Statues]\nGrid',
  circle = '[Place Statues]\nCircle\n(need set center point)',
  hexagon = '[Place Statues]\nHexagon\n(need set center point)',
  line = '[Place Statues]\nLine\n(need set start & end point)',
}
local index = 1 -- to cycle through layouts, need reset to 1 when greater than #LAYOUT.
local is_init = false -- is circles and first/second points initialized yet?
local is_enabled = false -- does player enable precise walk manually?
local is_carrying = false -- is player carrying heavy item?
local is_align_wall = false -- align to turf by default
local first_point = nil -- center of circle/hexagon, or start of line
local second_point = nil -- end of line

local function round(num) return math.floor(num + 0.5) end

local function InGame() return G.ThePlayer and G.ThePlayer.HUD and not G.ThePlayer.HUD:HasInputFocus() end

local function IsEnabled() return (InGame() and is_init) and (is_enabled or (AUTO_ENABLE and is_carrying)) end

local function GetCursorPosition()
  local p = G.TheInput:GetWorldPosition()
  return p.x, p.z
end

local function ManualToggle()
  if not InGame() then return end
  is_enabled = not is_enabled
  if is_enabled then
    Tip('[Place Statues] Precise Walk Enabled\nPlease disable lag compensation\n Use  to walk')
  else
    Tip('[Place Statues] Precise Walk Disabled')
  end
end

local function ChangeLayout()
  if not IsEnabled() then return end
  local x, z = GetPlayerPosition()
  first_point = G.Vector3(round(x), 0, round(z))
  index = index + 1
  if index > #LAYOUT then index = 1 end -- loop back to first element
  Tip(S[LAYOUT[index]])
end

local function ToggleAlignTarget()
  if not IsEnabled() then return end
  is_align_wall = not is_align_wall
  local target = is_align_wall and 'Wall' or 'Turf'
  Tip('[Place Statues] Align to ' .. target)
end

local function SetFirstPoint()
  if not IsEnabled() then return end
  local x, z = GetCursorPosition()
  first_point = G.Vector3(round(x), 0, round(z))
end

local function SetSecondPoint()
  if not IsEnabled() then return end
  local x, z = GetCursorPosition()
  second_point = G.Vector3(round(x), 0, round(z))
end

local callback = { -- config name to function called when the key event triggered
  manual_key = ManualToggle,
  layout_key = ChangeLayout,
  align_target_key = ToggleAlignTarget,
  first_point_key = SetFirstPoint,
  second_point_key = SetSecondPoint,
}

local handler = {} -- config name to key event handlers
function KeyBind(name, key)
  if handler[name] then handler[name]:Remove() end -- disable old binding
  if key ~= nil then -- new binding
    if key >= 1000 then -- it's a mouse button
      handler[name] = G.TheInput:AddMouseButtonHandler(function(button, down, x, y)
        if button == key and down then callback[name]() end
      end)
    else -- it's a keyboard key
      handler[name] = G.TheInput:AddKeyDownHandler(key, callback[name])
    end
  else -- no binding
    handler[name] = nil
  end
end

--------------------------------------------------------------------------------
-- circles and clicking on ground

PrefabFiles = { 'circleplacer' } -- for circles

local layout_fn = {} -- functions to apply layout, show circles and return destination point.
local indicators = {} -- small circles with different colors on ground

local function Show(inst, x, z)
  inst.Transform:SetPosition(x, -0.1, z)
  inst:Show()
end

layout_fn.grid = function(x, z)
  if is_align_wall then
    x = round(x + 0.5) - 0.5
    z = round(z + 0.5) - 0.5
  else
    x = round(x)
    z = round(z)
  end

  local offsets = { { -1, -1 }, { -1, 0 }, { -1, 1 }, { 0, -1 }, { 0, 1 }, { 1, -1 }, { 1, 0 }, { 1, 1 } }
  for i, indicator in ipairs(indicators) do
    local dx, dz = G.unpack(offsets[i])
    Show(indicator, x + dx, z + dz)
  end

  return x, z
end

layout_fn.circle = function(x, z)
  local delta_x = x - first_point.x
  local delta_z = z - first_point.z
  local radius = math.sqrt(delta_x ^ 2 + delta_z ^ 2)
  if radius < 1 then return x, z end

  local scale = round(radius)
  local angle_delta = math.pi * 2 / (math.floor((math.pi * scale * 2 / 4)) * 4)
  local angle = math.atan2(delta_x, delta_z)
  local step = angle / angle_delta
  step = is_align_wall and (round(step + 0.5) - 0.5) or round(step)
  angle = step * angle_delta

  for i, indicator in ipairs(indicators) do
    local t = (i > 4) and (i - 4) or -i
    local dx = math.sin(angle + t * angle_delta) * scale
    local dz = math.cos(angle + t * angle_delta) * scale
    Show(indicator, first_point.x + dx, first_point.z + dz)
  end

  return first_point.x + math.sin(angle) * scale, first_point.z + math.cos(angle) * scale
end

local R = math.sqrt(3) / 2 -- the height-to-width ratio of a regular hexagon
layout_fn.hexagon = function(x, z)
  if is_align_wall then
    z = (round((x - first_point.x) / R) % 2 ~= 1) and round(z) or (round(z + 0.5) - 0.5)
    x = first_point.x + round((x - first_point.x) / R) * R
  else
    x = (round((z - first_point.z) / R) % 2 ~= 1) and round(x) or (round(x + 0.5) - 0.5)
    z = first_point.z + round((z - first_point.z) / R) * R
  end

  local offsets = { { -0.5, -R }, { 0.5, -R }, { -1, 0 }, { 1, 0 }, { -0.5, R }, { 0.5, R } }
  for i, offset in ipairs(offsets) do
    local dx, dz = G.unpack(offset)
    if is_align_wall then
      dx, dz = dz, dx
    end
    Show(indicators[i], x + dx, z + dz)
  end

  return x, z
end

layout_fn.line = function(x, z)
  local delta_x, delta_z = x - first_point.x, z - first_point.z
  local delta_angle_x, delta_angle_z = second_point.x - first_point.x, second_point.z - first_point.z

  local radius_angle = math.sqrt(delta_angle_x ^ 2 + delta_angle_z ^ 2)
  if radius_angle == 0 then return x, z end

  local direction_angle = math.atan2(delta_angle_x, delta_angle_z)
  local radius = math.sqrt(delta_x ^ 2 + delta_z ^ 2)
  local scale = is_align_wall and (round(radius + 0.5) - 0.5) or round(radius)

  local step_x, step_z = math.sin(direction_angle) * scale, math.cos(direction_angle) * scale
  if step_x * delta_x < 0 and step_z * delta_z < 0 then
    step_x, step_z = -step_x, -step_z
  end
  x, z = first_point.x + step_x, first_point.z + step_z

  local direction = G.Vector3(delta_angle_x, 0, delta_angle_z) / radius_angle
  for i, indicator in ipairs(indicators) do
    local t = (i > 4) and (4 - i) or i
    Show(indicator, x + t * direction.x, z + t * direction.z)
  end

  return x, z
end

local function ApplyLayout()
  local x, z = GetCursorPosition()
  return layout_fn[LAYOUT[index]](x, z)
end

local function CreateIndicator(animation, scale)
  if G.PrefabExists('circleplacer') then
    circle = G.SpawnPrefab('circleplacer')
    circle.AnimState:PlayAnimation(animation, true)
    circle.Transform:SetScale(scale, scale, scale)
    return circle
  else
    return G.SpawnPrefab('gridplacer')
  end
end

AddComponentPostInit('playercontroller', function(self) -- injection
  G.ThePlayer:DoTaskInTime(0, function()
    -- create circles
    for i = 1, 8 do
      indicators[i] = CreateIndicator('off', 0.5) -- small red circles
    end
    indicators.destination = CreateIndicator('anim', 0.8) -- big cyan/blue circle
    indicators.first = CreateIndicator('on', 1) -- bigger green circle
    indicators.second = CreateIndicator('off', 1) -- bigger red circle

    -- initialize first/second points
    local x, z = GetPlayerPosition()
    first_point = G.Vector3(round(x), 0, round(z))
    second_point = G.Vector3(round(x + 4), 0, round(z + 4))

    is_init = true
  end)

  local OldOnUpdate = self.OnUpdate
  self.OnUpdate = function(self, ...)
    if not InGame() then return OldOnUpdate(self, ...) end

    -- is player carrying heavy item?
    local item = G.ThePlayer.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.BODY)
    is_carrying = item and item:HasTag('heavy')

    -- handle circles visibility
    for _, indicator in pairs(indicators) do
      indicator:Hide()
    end
    if IsEnabled() then
      local x, z = ApplyLayout()
      Show(indicators.destination, x, z)
      if LAYOUT[index] ~= 'grid' then Show(indicators.first, first_point.x, first_point.z) end
      if LAYOUT[index] == 'line' then Show(indicators.second, second_point.x, second_point.z) end
    end

    -- stop precise walk task if user presses to move or circles hidden
    local is_moving =
      self:IsAnyOfControlsPressed(G.CONTROL_MOVE_UP, G.CONTROL_MOVE_DOWN, G.CONTROL_MOVE_LEFT, G.CONTROL_MOVE_RIGHT)
    if is_moving or not IsEnabled() then StopPreciseWalk() end

    return OldOnUpdate(self, ...)
  end

  local OldOnLeftUp = self.OnLeftUp
  self.OnLeftUp = function(self)
    StopPreciseWalk()
    if not IsEnabled() or G.TheInput:GetHUDEntityUnderMouse() then return OldOnLeftUp(self) end
    target_x, target_z = ApplyLayout()
    walk_task = G.ThePlayer:DoTaskInTime(WALK_DELAY, StartPreciseWalk)
    return OldOnLeftUp(self)
  end
end)
