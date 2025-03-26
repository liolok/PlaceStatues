modimport('keybind')

PrefabFiles = { 'CirclePlacer' }
Assets = { Asset('ANIM', 'anim/circleplacer.zip') }

local G = GLOBAL

-- precise walk to target position
local WALK_DELAY = 0.8
local target_x, target_z = nil, nil
local walk_task = nil
local player_previous_x, player_previous_z = nil, nil
local should_stop_walk = false
local step_distance = nil

local CorrectionSetting = 0
local Settings = {
  [0] = '[Place Statues]\nGrid',
  [1] = '[Place Statues]\nCircle\n(need set center point)',
  [2] = '[Place Statues]\nHexagon\n(need set center point)',
  [3] = '[Place Statues]\nLine\n(need set start & end point)',
  -- Tranoze: If you are reading this, that mean you dig into my mod, this just a custom sculpture set up in my private version
  [4] = 'PentaCircle',
  [5] = 'CustomPentaLine', -- same as above
}
local TotalSetting = 4
local CenterLocate = nil
local SecondLocate = nil
local GridTweak = false

local function IsPlayerBusy()
  local is_idle = G.ThePlayer:HasTag('idle')
  local is_doing_or_working = G.ThePlayer.components.playercontroller:IsDoingOrWorking()
  return not is_idle or is_doing_or_working
end

function round(num)
  local under = math.floor(num)
  local upper = math.floor(num) + 1
  local underV = -(under - num)
  local upperV = upper - num
  if upperV > underV then
    return under
  else
    return upper
  end
end

local function NewPoint()
  local NPt
  if G.PrefabExists('circleplacer') then
    NPt = G.SpawnPrefab('circleplacer')
    NPt.AnimState:PlayAnimation('off', true)
    NPt.Transform:SetScale(0.5, 0.5, 0.5)
  else
    NPt = G.SpawnPrefab('gridplacer')
  end
  return NPt
end

local Closet

local function ClosetGenerate()
  Closet = {
    [0] = {},
    [1] = {},
    [2] = {},
    [3] = {},
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
  }
  for i = 0, 7 do
    if not Closet[i][0] then
      Closet[i][0] = NewPoint()
      Closet[i][1] = false
    end
  end
end

local is_enabled = false -- does player enable precise walk manually?
local is_carrying = false -- is player carrying heavy item?
local AUTO_ENABLE = GetModConfigData('auto_precise_walk') -- did user configure "Auto Precise Walk" to true?
local function IsEnabled() return is_enabled or (AUTO_ENABLE and is_carrying) end

local function HightlightCloset()
  if not IsEnabled() then return end
  for i = 0, 7 do
    if Closet[i][1] then
      Closet[i][0]:Show()
    else
      Closet[i][0]:Hide()
    end
  end
end

local function HideIndi()
  for i = 0, 7 do
    Closet[i][1] = false
    if Closet[i][0] then Closet[i][0]:Hide() end
  end
end

local Slut = 1
local function TurnCircle(pt)
  local bgx = pt.x
  local bgz = pt.z

  if CenterLocate == nil then return G.Vector3(bgx, 0, bgz) end

  local x = CenterLocate.x
  local z = CenterLocate.z

  local DeltaX = bgx - x
  local DeltaZ = bgz - z
  local radius = math.sqrt(DeltaX ^ 2 + DeltaZ ^ 2)

  if radius < 1 then
    bgx = x
    bgz = z
  else
    Scale = round(radius)

    local angleRutine = math.pi * 2 / (math.floor((math.pi * Scale * 2 / (4 * Slut))) * 4)

    local angle = math.atan2(DeltaX, DeltaZ)

    local step

    if not GridTweak then
      step = round(angle / angleRutine)
    else
      step = round(angle / angleRutine + 0.5) - 0.5
    end

    angle = step * angleRutine
    local Dltx = math.sin(angle) * Scale
    local Dltz = math.cos(angle) * Scale

    if Closet then
      for i = 0, 7 do
        if i < 4 then
          Closet[i][0].Transform:SetPosition(
            x + math.sin(angle - (i + 1) * angleRutine) * Scale,
            -0.1,
            z + math.cos(angle - (i + 1) * angleRutine) * Scale
          )
          Closet[i][1] = true
        else
          Closet[i][0].Transform:SetPosition(
            x + math.sin(angle + (i - 3) * angleRutine) * Scale,
            -0.1,
            z + math.cos(angle + (i - 3) * angleRutine) * Scale
          )
          Closet[i][1] = true
        end
      end
    end

    bgx = x + Dltx
    bgz = z + Dltz
  end
  return G.Vector3(bgx, 0, bgz)
end

local function Lineing(pt)
  local bgx = pt.x
  local bgz = pt.z
  if CenterLocate == nil or SecondLocate == nil then return G.Vector3(bgx, 0, bgz) end
  local x = CenterLocate.x
  local z = CenterLocate.z
  local DeltaX = bgx - x
  local DeltaZ = bgz - z
  local DeltaAngX = SecondLocate.x - x
  local DeltaAngZ = SecondLocate.z - z

  local rdiour = math.sqrt(DeltaAngX ^ 2 + DeltaAngZ ^ 2)
  if rdiour == 0 then return G.Vector3(bgx, 0, bgz) end

  local DireAng = math.atan2(DeltaAngX, DeltaAngZ)
  local radius = math.sqrt(DeltaX ^ 2 + DeltaZ ^ 2)
  if not GridTweak then
    Scale = round(radius)
  else
    Scale = round(radius + 0.5) - 0.5
  end
  local Dltx = math.sin(DireAng) * Scale
  local Dltz = math.cos(DireAng) * Scale

  if Dltx * DeltaX < 0 and Dltz * DeltaZ < 0 then
    Dltx = -Dltx
    Dltz = -Dltz
  end
  bgx = x + Dltx
  bgz = z + Dltz

  if Closet then
    local Direeer = G.Vector3(DeltaAngX, 0, DeltaAngZ) / rdiour

    for i = 0, 7 do
      if i < 4 then
        Closet[i][0].Transform:SetPosition(bgx + Direeer.x * (i + 1), 0, bgz + Direeer.z * (i + 1))
        Closet[i][1] = true
      else
        Closet[i][0].Transform:SetPosition(bgx - Direeer.x * (i - 3), 0, bgz - Direeer.z * (i - 3))
        Closet[i][1] = true
      end
    end
  end
  return G.Vector3(bgx, 0, bgz)
end

local function InGame() return G.ThePlayer and G.ThePlayer.HUD and not G.ThePlayer.HUD:HasInputFocus() end

local function GetPlayerPosition()
  local x, _, z = G.ThePlayer.Transform:GetWorldPosition()
  return x, z
end

local function GetDistances(x, z)
  local player_x, player_z = GetPlayerPosition()
  local dx = x - player_x
  local dz = z - player_z
  local d = math.sqrt(dx ^ 2 + dz ^ 2) -- the distance between player and given position
  return d, dx, dz
end

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
  if player_x == x and player_z == z then return end
  local distance, dx, dz = GetDistances(x, z)
  local delta = G.Vector3(dx, 0, dz) * DELTA_RATIO / distance
  WalkTo(player_x + delta.x, player_z + delta.z)
end

local function GetRoutePosition(player_radius)
  local d, dx, dz = GetDistances(target_x, target_z)
  if d == 0 then return nil end

  -- distance from player to its projection of target circle
  local dp = (player_radius ^ 2 - step_distance ^ 2 + d ^ 2) / (2 * d)
  if player_radius < dp then return nil end

  local player_x, player_z = GetPlayerPosition()
  local projection_x = player_x + dx * dp / d
  local projection_z = player_z + dz * dp / d

  local offset = math.sqrt(player_radius ^ 2 - dp ^ 2) -- perpendicular/height offset
  local intersection_x = projection_x + dz * offset / d
  local intersection_z = projection_z - dx * offset / d

  return G.Vector3(intersection_x, 0, intersection_z)
end

local function Tip(message) return G.ThePlayer.components.talker:Say(message) end

local function SayFinalDistance() Tip(tostring(GetDistances(target_x, target_z))) end

local function StopPreciseWalk()
  should_stop_walk = false
  step_distance = nil
  if walk_task then walk_task:Cancel() end
end

local function StartPreciseWalk(player)
  if IsPlayerBusy() then
    walk_task = player:DoTaskInTime(WALK_DELAY, StartPreciseWalk)
    return
  end
  if step_distance == nil then
    if player_previous_x == nil or player_previous_z == nil then
      player_previous_x, player_previous_z = GetPlayerPosition()
      BabyStepTo(target_x, target_z)
    else
      local d = GetDistances(player_previous_x, player_previous_z)
      if d > 0.01 then step_distance = d end
      player_previous_x, player_previous_z = nil, nil
    end
  else
    if GetDistances(target_x, target_z) > 0.3 then
      WalkTo(target_x, target_z)
    else
      if should_stop_walk then
        BabyStepTo(target_x, target_z)
        StopPreciseWalk()
        player:DoTaskInTime(WALK_DELAY, SayFinalDistance)
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
          player:DoTaskInTime(WALK_DELAY, SayFinalDistance)
          return
        end
      end
    end
  end
  walk_task = player:DoTaskInTime(WALK_DELAY, StartPreciseWalk)
end

local function GetCursorPosition()
  local p = G.TheInput:GetWorldPosition()
  return p.x, p.z
end

local function GetCorrectPoint()
  for i = 0, 7 do
    Closet[i][1] = false
  end
  local x, z = GetCursorPosition()

  if CorrectionSetting == 0 then -- Grid
    if not GridTweak then
      x = round(x)
      z = round(z)
    else
      x = round(x + 0.5) - 0.5
      z = round(z + 0.5) - 0.5
    end
    --ShowIndicator
    if Closet then
      Closet[0][0].Transform:SetPosition(x - 1, -0.1, z - 1)
      Closet[1][0].Transform:SetPosition(x - 1, -0.1, z)
      Closet[2][0].Transform:SetPosition(x - 1, -0.1, z + 1)
      Closet[3][0].Transform:SetPosition(x, -0.1, z - 1)
      Closet[4][0].Transform:SetPosition(x, -0.1, z + 1)
      Closet[5][0].Transform:SetPosition(x + 1, -0.1, z - 1)
      Closet[6][0].Transform:SetPosition(x + 1, -0.1, z)
      Closet[7][0].Transform:SetPosition(x + 1, -0.1, z + 1)
      for i = 0, 7 do
        Closet[i][1] = true
      end
    end
  elseif CorrectionSetting == 1 then -- Circle
    local SD = G.Vector3(x, y, z)
    local CircleSet = TurnCircle(SD)
    x = CircleSet.x
    z = CircleSet.z
    --AlreadyShowIndicator
  elseif CorrectionSetting == 2 then -- Hexa
    if not CenterLocate then return G.Vector3(x, 0, z) end

    if not GridTweak then
      if round((z - CenterLocate.z) / 0.86602540378) % 2 ~= 1 then
        x = round(x)
      else
        x = round(x + 0.5) - 0.5
      end
      local DeltaZ = z - CenterLocate.z
      DeltaZ = round(DeltaZ / 0.86602540378) * 0.86602540378
      z = DeltaZ + CenterLocate.z
    else
      if round((x - CenterLocate.x) / 0.86602540378) % 2 ~= 1 then
        z = round(z)
      else
        z = round(z + 0.5) - 0.5
      end
      local DeltaX = x - CenterLocate.x
      DeltaX = round(DeltaX / 0.86602540378) * 0.86602540378
      x = DeltaX + CenterLocate.x
    end
    --ShowIndicator
    if Closet then
      if not GridTweak then
        Closet[0][0].Transform:SetPosition(x - 0.5, -0.1, z - 0.86602540378)
        Closet[1][0].Transform:SetPosition(x + 0.5, -0.1, z - 0.86602540378)
        Closet[2][0].Transform:SetPosition(x - 1, -0.1, z)
        Closet[3][0].Transform:SetPosition(x + 1, -0.1, z)
        Closet[4][0].Transform:SetPosition(x - 0.5, -0.1, z + 0.86602540378)
        Closet[5][0].Transform:SetPosition(x + 0.5, -0.1, z + 0.86602540378)
      else
        Closet[0][0].Transform:SetPosition(x - 0.86602540378, -0.1, z - 0.5)
        Closet[1][0].Transform:SetPosition(x + 0.86602540378, -0.1, z - 0.5)
        Closet[2][0].Transform:SetPosition(x, -0.1, z - 1)
        Closet[3][0].Transform:SetPosition(x, -0.1, z + 1)
        Closet[4][0].Transform:SetPosition(x - 0.86602540378, -0.1, z + 0.5)
        Closet[5][0].Transform:SetPosition(x + 0.86602540378, -0.1, z + 0.5)
      end
      for i = 0, 5 do
        Closet[i][1] = true
      end
    end
  elseif CorrectionSetting == 3 then -- Line
    local SD = G.Vector3(x, y, z)
    local CircleSet = Lineing(SD)
    x = CircleSet.x
    z = CircleSet.z
  elseif CorrectionSetting == 4 then -- PentaCircle
    --local SD = G.Vector3(x,y,z)
    --local CircleSet = TurnPentaCircle(SD) -- a function in my private version of this mod
    --x = CircleSet.x
    --z = CircleSet.z
  elseif CorrectionSetting == 5 then -- CustomPentaLine
    --local SD = G.Vector3(x,y,z)
    --local CircleSet = PentaLine(SD)	-- a function in my private version of this mod
    --x = CircleSet.x
    --z = CircleSet.z
  end

  return x, z
end

local gridplacer
local function HightlightDrop()
  if not IsEnabled() then return end
  if not gridplacer then
    if G.PrefabExists('circleplacer') then
      gridplacer = G.SpawnPrefab('circleplacer')
      gridplacer.AnimState:PlayAnimation('anim', true)
      gridplacer.Transform:SetScale(0.8, 0.8, 0.8)
    else
      gridplacer = G.SpawnPrefab('gridplacer')
    end
  end
  gridplacer:Show()
  local x, z = GetCorrectPoint()
  gridplacer.Transform:SetPosition(x, -0.1, z)
  HightlightCloset()
end

local DropCenter
local function HightlightCenter()
  if not CenterLocate then return end
  if not DropCenter then
    if G.PrefabExists('circleplacer') then
      DropCenter = G.SpawnPrefab('circleplacer')
      DropCenter.AnimState:PlayAnimation('on', true)
      DropCenter.Transform:SetScale(1, 1, 1)
    else
      DropCenter = G.SpawnPrefab('gridplacer')
    end
  end
  if CorrectionSetting ~= 0 then
    DropCenter:Show()
  else
    DropCenter:Hide()
  end
  DropCenter.Transform:SetPosition(CenterLocate.x, -0.1, CenterLocate.z)
end

local SecondDrop
local function HightlightSecond()
  if not SecondLocate then return end
  if not SecondDrop then
    if G.PrefabExists('circleplacer') then
      SecondDrop = G.SpawnPrefab('circleplacer')
      SecondDrop.AnimState:PlayAnimation('off', true)
      SecondDrop.Transform:SetScale(1, 1, 1)
    else
      SecondDrop = G.SpawnPrefab('gridplacer')
    end
  end
  if CorrectionSetting == 3 then
    SecondDrop:Show()
  else
    SecondDrop:Hide()
  end
  SecondDrop.Transform:SetPosition(SecondLocate.x, -0.1, SecondLocate.z)
end

local function HideAll()
  if Tempo then Tempo:Hide() end
  if gridplacer then gridplacer:Hide() end
  if DropCenter then DropCenter:Hide() end
  if SecondDrop then SecondDrop:Hide() end
  HideIndi()
end

local function ChangePlacementType()
  if not CenterLocate then
    local x, z = GetCursorPosition()
    CenterLocate = G.Vector3(round(x), 0, round(z))
  end
  if not SecondLocate then
    local x, z = GetPlayerPosition()
    SecondLocate = G.Vector3(round(x), 0, round(z))
  end
  HideAll()
  CorrectionSetting = (CorrectionSetting + 1) % TotalSetting
  Tip(Settings[CorrectionSetting])
end

local function ToggleAlignTarget()
  GridTweak = not GridTweak
  if GridTweak then
    Tip('[Place Statues] Align to Wall')
  else
    Tip('[Place Statues] Align to Turf')
  end
end

local function SetFirstPoint()
  if not InGame() then return end
  local x, z = GetCursorPosition()
  CenterLocate = G.Vector3(round(x), 0, round(z))
end

local function SetSecondPoint()
  if not InGame() then return end
  local x, z = GetCursorPosition()
  SecondLocate = G.Vector3(round(x), 0, round(z))
  HightlightSecond()
end

local function ToggleIndicator()
  if IsEnabled() then
    HightlightCenter()
    HightlightSecond()
    HightlightDrop()
  else
    HideAll()
  end
end

local function TogglePreciseWalk()
  if not InGame() then return end
  is_enabled = not is_enabled
  if not is_enabled then
    Tip('[Place Statues] Precise Walk Disabled')
  else
    Tip('[Place Statues] Precision Walk Enabled\nPlease disable lag compensation\n Use  to walk')
  end
  ToggleIndicator()
end

local callback = { -- config name to function called when the key event triggered
  precise_walk_key = TogglePreciseWalk,
  placement_type_key = ChangePlacementType,
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

AddComponentPostInit('playercontroller', function(self)
  G.ThePlayer:DoTaskInTime(0, ClosetGenerate)

  local OldOnUpdate = self.OnUpdate
  self.OnUpdate = function(self, ...)
    if not InGame() then return OldOnUpdate(self, ...) end
    local item = G.ThePlayer.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.BODY)
    is_carrying = item and item:HasTag('heavy')
    ToggleIndicator()
    local is_moving =
      self:IsAnyOfControlsPressed(G.CONTROL_MOVE_UP, G.CONTROL_MOVE_DOWN, G.CONTROL_MOVE_LEFT, G.CONTROL_MOVE_RIGHT)
    if is_moving or not IsEnabled() then StopPreciseWalk() end
    return OldOnUpdate(self, ...)
  end

  local OldOnLeftUp = self.OnLeftUp
  self.OnLeftUp = function(self)
    StopPreciseWalk()
    if InGame() and IsEnabled() and G.TheInput:GetHUDEntityUnderMouse() == nil then
      target_x, target_z = GetCorrectPoint()
      walk_task = G.ThePlayer:DoTaskInTime(WALK_DELAY, StartPreciseWalk)
    end
    return OldOnLeftUp(self)
  end
end)
