PrefabFiles = {
	"CirclePlacer",
}
Assets = {
	Asset("ANIM", "anim/circleplacer.zip"),
}

local _G = GLOBAL

local require = _G.require
local SendRPCToServer = _G.SendRPCToServer
local TheInput = _G.TheInput
local Vector3 = _G.Vector3
local ACTIONS = _G.ACTIONS
local RPC = _G.RPC
local ThePlayer
local TheWorld
local BufferedAction = _G.BufferedAction

local Task = nil
local Timer = 0.8

local CorrectionSetting = 0
local Settings ={
[0] = "GridDrop",
[1] = "CircleDrop - Press P to set center",
[2] = "HexaDrop",
[3] = "Line - Press P and O to set 2 different point in the line",

[4] = "PentaCircle", -- If you are reading this, that mean you dig into my mod, this just a custom scupture set up in my private version
[5] = "CustomPentaLine" -- same as above
}
local TotalSetting = 4
local CenterLocate = nil
local SecondLocate = nil
local GridTweak = false
local Indicate = false
local Carrying = false

local function IsWalkButtonDown()
	return _G.ThePlayer.components.playercontroller:IsAnyOfControlsPressed(_G.CONTROL_MOVE_UP, _G.CONTROL_MOVE_DOWN, _G.CONTROL_MOVE_LEFT, _G.CONTROL_MOVE_RIGHT)
end
local function GetKeyConfig(configname, default)
	local value = GetModConfigData(configname)
	if type(value) == "string" and value:len() > 0 then
		return value:lower():byte()
	end
	if type(value) ~= "number" then
		return default:lower():byte()
	end
end

local CENTERBUTTON = GetKeyConfig("CENTERBUTTON", "P")
local SECONDPOINTDO = GetKeyConfig("SECONDPOINTDO", "O")
local DROPDEBUTT = GetKeyConfig("DROPDEBUTT", "Z")
local WALKINGTOGGLE = GetKeyConfig("WALKINGTOGGLE", "B")


function round(num)
    local under = math.floor(num)
    local upper = math.floor(num) + 1
    local underV = -(under - num)
    local upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end


local Tempo
local function HightlightTempo(x,z)
	if not Indicate and not Carrying then return end
	 if not Tempo then
        if _G.PrefabExists("circleplacer") then
			Tempo = _G.SpawnPrefab("circleplacer")
            Tempo.AnimState:PlayAnimation("off", true)
            Tempo.Transform:SetScale(1, 1, 1)
        else
            Tempo = _G.SpawnPrefab("gridplacer")			
        end
    end	
    Tempo:Show()	
    Tempo.Transform:SetPosition(x, -0.1, z)
end
	
local function NewPoint()
	local NPt
	if _G.PrefabExists("circleplacer") then
			NPt = _G.SpawnPrefab("circleplacer")
            NPt.AnimState:PlayAnimation("off", true)
            NPt.Transform:SetScale(0.5,0.5,0.5)
        else
            NPt = _G.SpawnPrefab("gridplacer")			
        end
	return NPt
end	

local Closet

local function ClosetGenerate()
	Closet = {
	[0] ={},
	[1] ={},
	[2] ={},
	[3] ={},
	[4] ={},
	[5] ={},
	[6] ={},
	[7] ={},
	}
	for i=0,7 do 
		if not Closet[i][0] then
			Closet[i][0] = NewPoint()
			Closet[i][1] = false 
		end
	end
end

local function HightlightCloset()
	
	if not Indicate and not Carrying then return end
	 for i=0,7 do 
		if  Closet[i][1] then
			Closet[i][0]:Show()
		else
			Closet[i][0]:Hide()
		end
	 end
end

local function HideIndi()
	 for i=0,7 do 
		 Closet[i][1] = false
		if  Closet[i][0] then  Closet[i][0]:Hide() end
	 end
end

local Slut = 1
local function TurnCircle(pt)
					
	local bgx = pt.x
	local bgz = pt.z
	
	
	if CenterLocate == nil then 
		 return Vector3(bgx,0,bgz)
	end
	
	local x =	CenterLocate.x 
	local z =	CenterLocate.z 
	
	local DeltaX = bgx - x
	local DeltaZ = bgz - z
	local radius = math.sqrt((DeltaX)^2 + (DeltaZ)^2)
	
	if radius < 1 then
	bgx = x
	bgz = z
	else
		Scale = round(radius)
		
		local angleRutine =math.pi*2/(math.floor((math.pi*(Scale)*2/(4*Slut)))*4)
		
		local angle = math.atan2(DeltaX,DeltaZ)
		
		local step 
		
		if not GridTweak then 
			step = round(angle/(angleRutine))
		else
			step = round(angle/(angleRutine) + 0.5) - 0.5
		end
		
		angle = step*angleRutine
		local Dltx = math.sin(angle)*(Scale )
		local Dltz = math.cos(angle)*(Scale )
		
		if Closet then
			for i=0,7 do 
				if i < 4 then
					Closet[i][0].Transform:SetPosition(x + math.sin(angle - (i + 1)*angleRutine)*(Scale ), -0.1,z + math.cos(angle - (i + 1)*angleRutine)*(Scale ))
					Closet[i][1] = true 
				else 
					Closet[i][0].Transform:SetPosition(x + math.sin(angle + (i - 3)*angleRutine)*(Scale ), -0.1,z + math.cos(angle + (i - 3)*angleRutine)*(Scale ))
					Closet[i][1] = true 
				end
			end
		end

		bgx = x + Dltx
		bgz = z + Dltz
	end
	return Vector3(bgx,0,bgz)
end



local function Lineing(pt)
	local bgx = pt.x
	local bgz = pt.z
	if CenterLocate == nil or SecondLocate == nil then 
		return Vector3(bgx,0,bgz)
	end
	local x =	CenterLocate.x 
	local z =	CenterLocate.z 
	local DeltaX = bgx - x
	local DeltaZ = bgz - z
	local DeltaAngX = SecondLocate.x - x
	local DeltaAngZ = SecondLocate.z - z
	
	local rdiour = math.sqrt((DeltaAngX)^2 + (DeltaAngZ)^2)
	if rdiour == 0 then return Vector3(bgx,0,bgz) end
	
	local DireAng = math.atan2(DeltaAngX, DeltaAngZ)
	local radius = math.sqrt((DeltaX)^2 + (DeltaZ)^2)
		if not GridTweak then
			Scale = round(radius)
		else
			Scale = round(radius+0.5)-0.5
		end
		local Dltx = math.sin(DireAng)*(Scale)
		local Dltz = math.cos(DireAng)*(Scale)
		
		if Dltx * DeltaX < 0 and Dltz * DeltaZ < 0 then 
			Dltx = -Dltx 
			Dltz = -Dltz
		end
		bgx = x + Dltx
		bgz = z + Dltz
		
		if Closet then
			local Direeer = Vector3(DeltaAngX, 0 , DeltaAngZ) / rdiour
			
			for i=0,7 do 
				if i < 4 then
					Closet[i][0].Transform:SetPosition(bgx + Direeer.x * (i + 1) , 0 , bgz + Direeer.z * (i + 1))
					Closet[i][1] = true 
				else 
					Closet[i][0].Transform:SetPosition(bgx - Direeer.x * (i - 3) , 0 , bgz - Direeer.z * (i - 3))
					Closet[i][1] = true 
				end
			end
		end
	return Vector3(bgx,0,bgz)
end

local function InGame()
    return ThePlayer and ThePlayer.HUD and not ThePlayer.HUD:HasInputFocus()
end

local function Distance(PointX, PointZ)
	local xx,yy,zz = ThePlayer.Transform:GetWorldPosition()
	local DelX = PointX - xx
	local DelZ = PointZ - zz
	return math.sqrt(DelX*DelX + DelZ*DelZ)
end
			
local function LongWalk(pos)
     local PlayerController = ThePlayer.components.playercontroller
    local act = BufferedAction(ThePlayer, nil, ACTIONS.WALKTO, ThePlayer.replica.inventory:GetActiveItem(), pos)	
    if PlayerController:CanLocomote() then
        act.preview_cb = function()
            SendRPCToServer(RPC.LeftClick, act.action.code, pos.x, pos.z, nil, true)
        end	
        PlayerController:DoAction(act)
    else
        SendRPCToServer(RPC.LeftClick, act.action.code, pos.x, pos.z, nil, nil, nil, act.action.canforce)
    end	
end

local function ShortStep(pos)
	if pos then
		local Distate = Distance(pos.x, pos.z)
		if Distate > 0 then
			local xx, yy, zz = ThePlayer.Transform:GetWorldPosition()
			local Direct = (Vector3(pos.x - xx , 0,pos.z - zz) / Distate ) * 0.165
			local Destination = Vector3(xx + Direct.x, 0, zz + Direct.z)
			LongWalk(Destination)
		end
	end
end

local function GetRoutePos(Radius0, x1, z1, Radius1)
	local x0, y0, z0 = ThePlayer.Transform:GetWorldPosition()
	local d=math.sqrt((x1-x0)*(x1-x0) + (z1-z0)*(z1-z0))
	if d == 0 then
		return nil
	end
	local a=(Radius0*Radius0-Radius1*Radius1+d*d)/(2*d)
	if Radius0 < a then
		return nil
	end
	local h=math.sqrt(Radius0*Radius0-a*a)
	local x2=x0+a*(x1-x0)/d   
	local z2=z0+a*(z1-z0)/d 
	
	local x3=x2+h*(z1-z0)/d       
	local z3=z2-h*(x1-x0)/d	
	--print(tostring(math.sqrt((x3-x1)*(x3-x1) + (z3-z1)*(z3-z1))))
	
	return Vector3(x3,0,z3)
end

local PreviousPlayerPost = nil
local AngleStep = true


local function SayFinalDistance(inst,PointX, PointZ)
	GLOBAL.ThePlayer.components.talker:Say(tostring(Distance(PointX, PointZ)))
end

local function Wonlerina(inst, PointX, PointZ, StepDistance)
	local Distate = 0
	if IsWalkButtonDown() then return end
	if GLOBAL.ThePlayer:HasTag("idle") and not GLOBAL.ThePlayer.components.playercontroller:IsDoingOrWorking() then 
		if StepDistance>0  then
			if Distance(PointX,PointZ) > 0.3 then
				LongWalk(Vector3(PointX, 0, PointZ))			
			else
				if AngleStep then
					local RelativeDistance = math.floor(Distance(PointX,PointZ)/StepDistance)
					if RelativeDistance < 2 then
						AngPos = GetRoutePos(StepDistance,PointX,PointZ,StepDistance)
						if AngPos then
							ShortStep(AngPos)
							AngleStep = false
						else
							AngleStep = true
							Task = nil
							ThePlayer:DoTaskInTime(Timer,SayFinalDistance,PointX,PointZ)
							return
						end
					else
						AngPos = GetRoutePos(RelativeDistance * StepDistance,PointX,PointZ,StepDistance)
						if AngPos then
							ShortStep(AngPos)
						else
							AngleStep = true
							Task = nil
							ThePlayer:DoTaskInTime(Timer,SayFinalDistance,PointX,PointZ)
							return
						end
					end
				else
					ShortStep(Vector3(PointX,0,PointZ))
					AngleStep = true
					Task = nil
					ThePlayer:DoTaskInTime(Timer,SayFinalDistance,PointX,PointZ)
					return
				end
			end
		else
			if PreviousPlayerPost == nil then
				local xx,yy,zz = ThePlayer.Transform:GetWorldPosition()
				PreviousPlayerPost = Vector3(xx,yy,zz)
				ShortStep(Vector3(PointX, 0, PointZ))	
			else
				local xx,yy,zz = ThePlayer.Transform:GetWorldPosition()
				local xD = PreviousPlayerPost.x - xx
				local zD = PreviousPlayerPost.z - zz
				local Dist = math.sqrt(xD*xD + zD*zD)
				if Dist > 0.01 then
					Distate = Dist
				end
				PreviousPlayerPost = nil
			end
		end
	end
	if Distate > 0 then 
	Task = ThePlayer:DoTaskInTime(Timer,Wonlerina,PointX,PointZ,Distate)
	else
	Task = ThePlayer:DoTaskInTime(Timer,Wonlerina,PointX,PointZ,StepDistance)
	end
end


local function GetCorrectPoint()
	for i=0,7 do Closet[i][1] = false end
	local x = TheInput:GetWorldPosition().x
	local z = TheInput:GetWorldPosition().z
	
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
			for i=0,7 do Closet[i][1] = true end
		end
		
	elseif CorrectionSetting == 1 then -- Circle
		local SD = Vector3(x,y,z)
		local CircleSet = TurnCircle(SD)
		x = CircleSet.x
		z = CircleSet.z
		--AlreadyShowIndicator
	elseif CorrectionSetting == 2 then -- Hexa
		if not CenterLocate then return Vector3(x,0,z) end
		
		if not GridTweak then
			if round ((z - CenterLocate.z)/0.86602540378) % 2 ~= 1 then 
				x = round(x)
			else 			
				x = round(x + 0.5) - 0.5
			end
			local DeltaZ = z - CenterLocate.z	
			DeltaZ = round(DeltaZ / 0.86602540378) * 0.86602540378
			z = DeltaZ + CenterLocate.z
		else
			if round ((x - CenterLocate.x)/0.86602540378) % 2 ~= 1 then 
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
			for i=0,5 do Closet[i][1] = true end
		end
	elseif CorrectionSetting == 3 then -- Line
		local SD = Vector3(x,y,z)
		local CircleSet = Lineing(SD)
		x = CircleSet.x
		z = CircleSet.z
	elseif CorrectionSetting == 4 then -- PentaCircle
		--local SD = Vector3(x,y,z)
		--local CircleSet = TurnPentaCircle(SD) -- a function in my private version of this mod
		--x = CircleSet.x
		--z = CircleSet.z
	
	elseif CorrectionSetting == 5 then -- CustomPentaLine
		--local SD = Vector3(x,y,z)
		--local CircleSet = PentaLine(SD)	-- a function in my private version of this mod
		--x = CircleSet.x
		--z = CircleSet.z
	end
	
	
	return Vector3(x,0,z)
end		

local gridplacer
local function HightlightDrop()

	if not Indicate and not Carrying then return end
    if not gridplacer then
        if _G.PrefabExists("circleplacer") then
			gridplacer = _G.SpawnPrefab("circleplacer")
            gridplacer.AnimState:PlayAnimation("anim", true)
            gridplacer.Transform:SetScale(0.8, 0.8, 0.8)
        else
            gridplacer = _G.SpawnPrefab("gridplacer")			
        end
    end	
    gridplacer:Show()	
	local SD = GetCorrectPoint()
    gridplacer.Transform:SetPosition(SD.x, -0.1, SD.z)	
	HightlightCloset()
end

local DropCenter
local function HightlightCenter()

	if not CenterLocate then
		return 
	end
	 if not DropCenter then
        if _G.PrefabExists("circleplacer") then
			DropCenter = _G.SpawnPrefab("circleplacer")
            DropCenter.AnimState:PlayAnimation("on", true)
            DropCenter.Transform:SetScale(1, 1, 1)
        else
            DropCenter = _G.SpawnPrefab("gridplacer")			
        end
    end	
    if CorrectionSetting ~= 0  then
		DropCenter:Show()	
	else 
		DropCenter:Hide()	
	end
    DropCenter.Transform:SetPosition(CenterLocate.x, -0.1, CenterLocate.z)
end


local SecondDrop
local function HightlightSecond()
	if not SecondLocate then
	return
	end
	 if not SecondDrop then
        if _G.PrefabExists("circleplacer") then
			SecondDrop = _G.SpawnPrefab("circleplacer")
            SecondDrop.AnimState:PlayAnimation("off", true)
            SecondDrop.Transform:SetScale(1, 1, 1)
        else
            SecondDrop = _G.SpawnPrefab("gridplacer")			
        end
    end	
	if CorrectionSetting == 3  then
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
	
	
GLOBAL.TheInput:AddKeyDownHandler(CENTERBUTTON, function()
	if not InGame() then return end	
	if not TheInput:IsKeyDown(GLOBAL.KEY_CTRL) then
		
		local xx = round(TheInput:GetWorldPosition().x)
		local zz = round(TheInput:GetWorldPosition().z)
		CenterLocate = Vector3(xx,0,zz)
	else
		if not CenterLocate then
			local xx = round(TheInput:GetWorldPosition().x)
			local zz = round(TheInput:GetWorldPosition().z)
			CenterLocate = Vector3(xx,0,zz)
		end 
		if not SecondLocate then 
			local xx,yy,zz = ThePlayer.Transform:GetWorldPosition()
			xx = round (xx)
			zz= round (zz)
			SecondLocate = Vector3(xx,0,zz)
		end
		HideAll()
		CorrectionSetting = (CorrectionSetting + 1) % TotalSetting
		GLOBAL.ThePlayer.components.talker:Say(Settings[CorrectionSetting].."\n Press Ctr+O to tweak position by 0.5")
	end
end)
GLOBAL.TheInput:AddKeyDownHandler(SECONDPOINTDO, function()
	if not InGame() then return end	
		if not TheInput:IsKeyDown(GLOBAL.KEY_CTRL) then
		local xx = round(TheInput:GetWorldPosition().x)
		local zz = round(TheInput:GetWorldPosition().z)
		SecondLocate = Vector3(xx,0,zz)
		HightlightSecond()
	else
		GridTweak = not GridTweak
		if GridTweak then
			GLOBAL.ThePlayer.components.talker:Say("Tweaked")
		else
			GLOBAL.ThePlayer.components.talker:Say("UnTweaked")
		end
	end
end)


GLOBAL.TheInput:AddKeyDownHandler(DROPDEBUTT , function()
    if not InGame() then return end	
				local StatueB = _G.EQUIPSLOTS.BODY  
				local Statue = ThePlayer.replica.inventory:GetEquippedItem(StatueB)
				if Statue and Statue:HasTag("heavy") then 
					ThePlayer.replica.inventory:DropItemFromInvTile(Statue)
				end
end)

local IsIndicate = false
local function ToggleIndicator()
		IsIndicate = Indicate or Carrying

		if not IsIndicate then
			HideAll()
		else
			HightlightCenter()
			HightlightSecond()
			HightlightDrop()	
		end
end
GLOBAL.TheInput:AddKeyDownHandler(WALKINGTOGGLE, function()
	if not InGame() then return end	
	--Turn on/off indicator
	Indicate = not Indicate
	if not Indicate then
			GLOBAL.ThePlayer.components.talker:Say("Disabled precision Walking") 
		else
			GLOBAL.ThePlayer.components.talker:Say("Precision Walking\n Please disable lag compensation\n Use  to walk") 	
		end
	ToggleIndicator()
end)


AddComponentPostInit("playercontroller", function(self)
    ThePlayer = _G.ThePlayer
    TheWorld = _G.TheWorld
	ThePlayer:DoTaskInTime(0,ClosetGenerate)
end)

PlayerController = require("components/playercontroller")
local OldOnUpdate = PlayerController.OnUpdate

function PlayerController:OnUpdate(Time)
	if InGame() then
		local StatueB = _G.EQUIPSLOTS.BODY  
				local Statue = ThePlayer.replica.inventory:GetEquippedItem(StatueB)
				if Statue and Statue:HasTag("heavy") then 
					Carrying = true
				else
					Carrying = false
				end
		ToggleIndicator()
		
	end
	return OldOnUpdate(self,Time)
end

local OldOnLeftClick = PlayerController.OnLeftUp

function PlayerController:OnLeftUp()
	if InGame() and IsIndicate and TheInput:GetHUDEntityUnderMouse() == nil then	
		if Task~= nil then
		Task:Cancel()
		Task = nil
		end
		
		local  Posit = GetCorrectPoint()
		Task = ThePlayer:DoTaskInTime(Timer,Wonlerina,Posit.x,Posit.z,0)
		
	end
	return OldOnLeftClick(self)
end
