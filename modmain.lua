modimport('keybind')

PrefabFiles = { 'CirclePlacer' }
Assets = { Asset('ANIM', 'anim/circleplacer.zip') }

local G = GLOBAL

local Task = nil
local WALK_DELAY = 0.8

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

local function IsWalkButtonDown()
  return G.ThePlayer.components.playercontroller:IsAnyOfControlsPressed(
    G.CONTROL_MOVE_UP,
    G.CONTROL_MOVE_DOWN,
    G.CONTROL_MOVE_LEFT,
    G.CONTROL_MOVE_RIGHT
  )
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

local function CalculateDistance(target_x, target_z)
  local player_x, player_z = GetPlayerPosition()
  local dx = target_x - player_x
  local dz = target_z - player_z
  return math.sqrt(dx ^ 2 + dz ^ 2)
end

local function LongWalk(pos)
  local act = G.BufferedAction(G.ThePlayer, nil, G.ACTIONS.WALKTO, G.ThePlayer.replica.inventory:GetActiveItem(), pos)
  if G.ThePlayer.components.playercontroller:CanLocomote() then
    act.preview_cb = function() G.SendRPCToServer(G.RPC.LeftClick, act.action.code, pos.x, pos.z, nil, true) end
    G.ThePlayer.components.playercontroller:DoAction(act)
  else
    G.SendRPCToServer(G.RPC.LeftClick, act.action.code, pos.x, pos.z, nil, nil, nil, act.action.canforce)
  end
end

local function ShortStep(pos)
  if pos then
    local distance = CalculateDistance(pos.x, pos.z)
    if distance > 0 then
      local x, z = GetPlayerPosition()
      local direction = (G.Vector3(pos.x - x, 0, pos.z - z) / distance) * 0.165
      local destination = G.Vector3(x + direction.x, 0, z + direction.z)
      LongWalk(destination)
    end
  end
end

local function GetRoutePosition(player_radius, target_radius, x, z)
  local d = CalculateDistance(x, z) -- distance between centers of player circle and target circle
  if d == 0 then return nil end

  --  distance from player to its projection of target circle
  local dp = (player_radius ^ 2 - target_radius ^ 2 + d ^ 2) / (2 * d)
  if player_radius < dp then return nil end

  local player_x, player_z = GetPlayerPosition()
  local dx, dz = x - player_x, z - player_z
  local projection_x = player_x + dx * dp / d
  local projection_z = player_z + dz * dp / d

  local offset = math.sqrt(player_radius ^ 2 - dp ^ 2) -- perpendicular/height offset
  local intersection_x = projection_x + dz * offset / d
  local intersection_z = projection_z - dx * offset / d

  return G.Vector3(intersection_x, 0, intersection_z)
end

local PreviousPlayerPost = nil
local AngleStep = true

local function SayFinalDistance(inst, PointX, PointZ)
  G.ThePlayer.components.talker:Say(tostring(CalculateDistance(PointX, PointZ)))
end

local function StartPreciseWalk(inst, PointX, PointZ, StepDistance)
  local Distate = 0
  if IsWalkButtonDown() then return end
  if G.ThePlayer:HasTag('idle') and not G.ThePlayer.components.playercontroller:IsDoingOrWorking() then
    if StepDistance then
      if CalculateDistance(PointX, PointZ) > 0.3 then
        LongWalk(G.Vector3(PointX, 0, PointZ))
      else
        if AngleStep then
          local RelativeDistance = math.floor(CalculateDistance(PointX, PointZ) / StepDistance)
          if RelativeDistance < 2 then
            AngPos = GetRoutePosition(StepDistance, StepDistance, PointX, PointZ)
            if AngPos then
              ShortStep(AngPos)
              AngleStep = false
            else
              AngleStep = true
              Task = nil
              G.ThePlayer:DoTaskInTime(WALK_DELAY, SayFinalDistance, PointX, PointZ)
              return
            end
          else
            AngPos = GetRoutePosition(RelativeDistance * StepDistance, StepDistance, PointX, PointZ)
            if AngPos then
              ShortStep(AngPos)
            else
              AngleStep = true
              Task = nil
              G.ThePlayer:DoTaskInTime(WALK_DELAY, SayFinalDistance, PointX, PointZ)
              return
            end
          end
        else
          ShortStep(G.Vector3(PointX, 0, PointZ))
          AngleStep = true
          Task = nil
          G.ThePlayer:DoTaskInTime(WALK_DELAY, SayFinalDistance, PointX, PointZ)
          return
        end
      end
    else
      if PreviousPlayerPost == nil then
        local player_x, player_z = GetPlayerPosition()
        PreviousPlayerPost = G.Vector3(player_x, 0, player_z)
        ShortStep(G.Vector3(PointX, 0, PointZ))
      else
        local d = CalculateDistance(PreviousPlayerPost.x, PreviousPlayerPost.z)
        if d > 0.01 then Distate = d end
        PreviousPlayerPost = nil
      end
    end
  end
  if Distate > 0 then
    Task = G.ThePlayer:DoTaskInTime(WALK_DELAY, StartPreciseWalk, PointX, PointZ, Distate)
  else
    Task = G.ThePlayer:DoTaskInTime(WALK_DELAY, StartPreciseWalk, PointX, PointZ, StepDistance)
  end
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

  return G.Vector3(x, 0, z)
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
  local SD = GetCorrectPoint()
  gridplacer.Transform:SetPosition(SD.x, -0.1, SD.z)
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
  G.ThePlayer.components.talker:Say(Settings[CorrectionSetting])
end

local function ToggleAlignTarget()
  GridTweak = not GridTweak
  if GridTweak then
    G.ThePlayer.components.talker:Say('[Place Statues] Align to Wall')
  else
    G.ThePlayer.components.talker:Say('[Place Statues] Align to Turf')
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
    G.ThePlayer.components.talker:Say('[Place Statues] Precise Walk Disabled')
  else
    G.ThePlayer.components.talker:Say(
      '[Place Statues] Precision Walk Enabled\nPlease disable lag compensation\n Use  to walk'
    )
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
    if InGame() then
      local item = G.ThePlayer.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.BODY)
      is_carrying = item and item:HasTag('heavy')
      ToggleIndicator()
    end
    return OldOnUpdate(self, ...)
  end

  local OldOnLeftUp = self.OnLeftUp
  self.OnLeftUp = function(self)
    if InGame() and IsEnabled() and G.TheInput:GetHUDEntityUnderMouse() == nil then
      if Task ~= nil then
        Task:Cancel()
        Task = nil
      end

      local pos = GetCorrectPoint()
      Task = G.ThePlayer:DoTaskInTime(WALK_DELAY, StartPreciseWalk, pos.x, pos.z)
    end
    return OldOnLeftUp(self)
  end
end)
