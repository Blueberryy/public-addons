AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "gBalloon Target"
ENT.Category = "RotgB: Miscellaneous"
ENT.ScriptedEntityType = "entity"
ENT.Author = "Piengineer"
ENT.Contact = "http://steamcommunity.com/id/Piengineer12/"
ENT.Purpose = "As a target for rouge gBalloons."
ENT.Instructions = ""
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.Editable = true
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.DisableDuplicator = false

ROTGB_CASH = ROTGB_CASH or 0

function ROTGB_UpdateCash(ply)
	if SERVER then
		net.Start("rotgb_cash")
		net.WriteUInt(ply and ply:UserID() or 0, 16)
		net.WriteDouble(ROTGB_GetCash(ply))
		net.Broadcast()
	end
end

function ROTGB_SetCash(num,ply)
	if GetConVar("rotgb_individualcash"):GetBool() then
		if ply then
			ply.ROTGB_CASH = tonumber(num) or 0
			ROTGB_UpdateCash(ply)
		else
			for k,v in pairs(player.GetAll()) do
				v.ROTGB_CASH = tonumber(num) or 0
				ROTGB_UpdateCash(v)
			end
		end
	else
		ROTGB_CASH = tonumber(num) or 0
		ROTGB_UpdateCash()
	end
end

function ROTGB_GetCash(ply)
	if GetConVar("rotgb_individualcash"):GetBool() then
		ply = ply or CLIENT and LocalPlayer()
		if ply then return ply.ROTGB_CASH or 0
		else
			local average = 0
			for k,v in pairs(player.GetAll()) do
				average = average + v.ROTGB_CASH
			end
			return average
		end
	else
		return ROTGB_CASH or 0
	end
end

function ROTGB_AddCash(num,ply)
	num = tonumber(num) or 0
	if GetConVar("rotgb_individualcash"):GetBool() then
		if ply then
			ROTGB_SetCash(ROTGB_GetCash(ply)+num,ply)
		else
			local count = player.GetCount()
			for k,v in pairs(player.GetAll()) do
				ROTGB_SetCash(ROTGB_GetCash(v)+num/count,v)
			end
		end
	else
		ROTGB_SetCash(ROTGB_GetCash()+num)
	end
end

function ROTGB_RemoveCash(num,ply)
	num = tonumber(num) or 0
	if GetConVar("rotgb_individualcash"):GetBool() then
		if ply then
			ROTGB_SetCash(ROTGB_GetCash(ply)-num,ply)
		else
			local count = player.GetCount()
			for k,v in pairs(player.GetAll()) do
				ROTGB_SetCash(ROTGB_GetCash(v)-num/count,v)
			end
		end
	else
		ROTGB_SetCash(ROTGB_GetCash()-num)
	end
end

function ROTGB_GetTransferAmount(ply)
	local cash = ROTGB_GetCash(ply)
	if not cash == cash then return cash end
	return math.floor(math.max(0, cash / 5, math.min(cash, 100)))
end

function ROTGB_ScaleBuyCost(num)
	return num * (1 + (GetConVar("rotgb_difficulty"):GetFloat() - 1)/5)
end

local ConH,ConE,ConX,ConY,ConS,ConF,ConG,ConQ

if SERVER then
	hook.Add("Think","RotgB2",function()
		if ROTGB_GetCash()==0 and GetConVar("rotgb_starting_cash"):GetFloat()~=0 then
			ROTGB_SetCash(GetConVar("rotgb_starting_cash"):GetFloat())
		elseif player.GetCount() > 0 then
			hook.Remove("Think","RotgB2")
		end
	end)
	
	hook.Add("PlayerSpawn","RotgB2",function(ply)
		if GetConVar("rotgb_individualcash"):GetBool() and GetConVar("rotgb_starting_cash"):GetFloat()~=0 then
			ROTGB_SetCash(GetConVar("rotgb_starting_cash"):GetFloat(), ply)
		end
	end)
	
	util.AddNetworkString("rotgb_target_received_damage")
	util.AddNetworkString("rotgb_cash")
end

if CLIENT then -- START CLIENT

function ROTGB_FormatCash(cash, roundUp)
	if cash==math.huge then -- number is inf
		return "$∞"
	elseif cash==-math.huge then -- number is negative inf
		return "$-∞"
	elseif cash<math.huge and cash>-math.huge then -- number is real
		return "$"..string.Comma((roundUp and math.ceil or math.floor)(cash))
	else -- number isn't a number. Caused by inf minus inf
		return "$?"
	end
end

ConH = CreateClientConVar("rotgb_hoverover_distance","15",true,false,
[[Determines the height of the text hovering above the gBalloon Spawner and gBalloon Targets.]])

ConE = CreateClientConVar("rotgb_hud_enabled","1",true,false,
[[Determines the visibility of the cash and gBalloon Target health display.]])

ConX = CreateClientConVar("rotgb_hud_x","0.1",true,false,
[[Determines the horizontal position of the cash display.]])

ConY = CreateClientConVar("rotgb_hud_y","0.1",true,false,
[[Determines the vertical position of the cash display.]])

ConS = CreateClientConVar("rotgb_hud_size","32",true,false,
[[Determines the size of the cash display.]])

ConF = CreateClientConVar("rotgb_freeze_effect","0",true,false,
[[Shows the freezing effect when a gBalloon is frozen.
 - Only enable this if you have a high-end PC.]])

ConG = CreateClientConVar("rotgb_no_glow","0",true,false,
[[Disable all halo effects, including the turquoise halo around purple gBalloons.
 - Only enable this if you have a low-end PC.]])

ConQ = CreateClientConVar("rotgb_circle_segments","24",true,false,
[[Sets the number of sides each drawn "circle" has.
 - Lowering this value can improve performance.]])

local function CreateGBFont(fontsize)
	surface.CreateFont("RotgB_font",{
		font="Luckiest Guy",
		size=fontsize
	})
end

CreateGBFont(32)

local function FilterSequentialTable(tab,func)
	local filtered = {}
	for i,v in ipairs(tab) do
		if func(i,v) then
			table.insert(filtered, v)
		end
	end
	return filtered
end

local function TableFilterWaypoints(k,v)
	return IsValid(v) and v:GetClass()=="gballoon_target" and not v:GetIsBeacon() and not v:GetHideHealth()
end

local function TableFilterNonSpawners(k,v)
	return IsValid(v) and v:GetClass()=="gballoon_spawner"
end

local function WaypointSorter(a,b)
	return a:GetWeight() > b:GetWeight()
end

local function SpawnerSorter(a,b)
	return a:GetWave() > b:GetWave()
end

net.Receive("rotgb_cash", function()
	local id = net.ReadUInt(16)
	local amt = net.ReadDouble()
	if id==0 then
		ROTGB_CASH = amt
	elseif IsValid(Player(id)) then
		Player(id).ROTGB_CASH = amt
	end
end)

local hurtFeed = {}
local hurtFeedStaySeconds = 10
net.Receive("rotgb_target_received_damage", function()
	local target = net.ReadEntity()
	local newHealth = net.ReadInt(32)
	local attackerLabel = net.ReadString()
	local damage = net.ReadInt(32)
	local flags = net.ReadUInt(8)
	local timestamp = net.ReadFloat()
	local displayName = "<unknown>"
	local isBalloon = bit.band(flags,1)==1
	local color
	
	if IsValid(target) then
		target.rotgb_ActualHealth = newHealth
	end
	
	if bit.band(flags,2)==2 then
		local ply = Player(tonumber(attackerLabel))
		if IsValid(ply) then
			displayName = ply:Nick()
			color = team.GetColor(ply:Team())
		end
	elseif isBalloon then
		local npcTable = list.GetForEdit("NPC")[attackerLabel]
		displayName = npcTable.Name
		if bit.band(flags,32)==32 then
			displayName = "Shielded "..displayName
		end
		if bit.band(flags,16)==16 then
			displayName = "Regen "..displayName
		end
		if bit.band(flags,8)==8 then
			displayName = "Hidden "..displayName
		end
		if bit.band(flags,4)==4 then
			displayName = "Fast "..displayName
		end
		local h,s,v = ColorToHSV(string.ToColor(npcTable.KeyValues.BalloonColor))
		if s == 1 then v = 1 end
		s = s / 2
		v = (v + 1) / 2
		color = HSVToColor(h,s,v)
	else
		displayName = language.GetPhrase(attackerLabel)
	end
	
	local existingEntry = hurtFeed[displayName]
	if existingEntry then
		existingEntry.damage = existingEntry.damage + damage
		existingEntry.timestamp = timestamp
		existingEntry.instances = existingEntry.instances + 1
	else
		hurtFeed[displayName] = {
			damage = damage,
			timestamp = timestamp,
			instances = 1,
			color = color,
			isBalloon = isBalloon
		}
	end
end)

local wavemat = Material("icon16/flag_green.png")
local coinmat = Material("icon16/coins.png")
local heartmat = Material("icon16/heart.png")
local oldSize = 0
local generateCooldown = 1
hook.Add("HUDPaint","RotgB",function()
	if ConE:GetBool() then
		local spawners = FilterSequentialTable(ents.GetAll(), TableFilterNonSpawners)
		table.sort(spawners, SpawnerSorter)
		for k,v in pairs(spawners) do
			spawners[k] = string.Comma(v:GetWave()-1).." / "..string.Comma(v:GetLastWave())
		end
		
		local targets = FilterSequentialTable(ents.GetAll(), TableFilterWaypoints)
		table.sort(targets, WaypointSorter)
		for k,v in pairs(targets) do
			if v.rotgb_ActualHealth then
				if v.rotgb_ActualHealth > v:Health() then
					targets[k] = string.Comma(v:Health())
					v.rotgb_ActualHealth = nil
				else
					targets[k] = string.Comma(v.rotgb_ActualHealth)
				end
			else
				targets[k] = string.Comma(v:Health())
			end
		end
		
		local size = ConS:GetFloat()
		if oldSize ~= size then
			oldSize = size
			generateCooldown = RealTime() + 1
		end
		if generateCooldown < RealTime() and generateCooldown >= 0 then
			generateCooldown = -1
			CreateGBFont(size)
		end
		local xPos = ConX:GetFloat()*ScrW()
		local yPos = ConY:GetFloat()*ScrH()
		surface.SetDrawColor(255,255,255)
		surface.SetMaterial(wavemat)
		surface.DrawTexturedRect(xPos,yPos,size,size)
		surface.SetMaterial(heartmat)
		surface.DrawTexturedRect(xPos,yPos+size,size,size)
		surface.SetMaterial(coinmat)
		surface.DrawTexturedRect(xPos,yPos+size*2,size,size)
		
		local textX = xPos+size+2
		
		if next(spawners) then
			draw.SimpleTextOutlined(table.concat(spawners, " + "),"RotgB_font",textX,yPos,color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP,2,color_black)
		else
			draw.SimpleTextOutlined("0","RotgB_font",textX,yPos,color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP,2,color_black)
		end
		
		if next(targets) then
			draw.SimpleTextOutlined(table.concat(targets, " + "),"RotgB_font",textX,yPos+size,color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP,2,color_black)
		else
			draw.SimpleTextOutlined("0","RotgB_font",textX,yPos+size,color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP,2,color_black)
		end
		
		draw.SimpleTextOutlined(ROTGB_FormatCash(ROTGB_GetCash(LocalPlayer())),"RotgB_font",textX,yPos+size*2,color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP,2,color_black)
		
		for k,v in pairs(hurtFeed) do
			if v.timestamp + hurtFeedStaySeconds < CurTime() then
				hurtFeed[k] = nil
			end
		end
		
		local hurtFeedKeyless = table.ClearKeys(hurtFeed, true)
		table.sort(hurtFeedKeyless, function(a,b)
			return a.damage > b.damage
		end)
		
		local textOffset = size*3
		for i,v in ipairs(hurtFeedKeyless) do
			local attributed = v.isBalloon and v.instances > 1 and string.format("%ux %s", v.instances, v.__key) or v.__key
			local textPart1 = "Took "..string.Comma(v.damage).." damage from "
			local textPart2 = "!"
			local alpha = math.Remap(CurTime(), v.timestamp, v.timestamp+hurtFeedStaySeconds, 512, 0)
			local fgColor = Color(255, 255, 255, math.min(alpha, 255))
			local fgColor2 = v.color or fgColor
			fgColor2 = Color(fgColor2.r, fgColor2.g, fgColor2.b, math.min(alpha, 255))
			local bgColor = Color(0, 0, 0, math.min(alpha, 255))
			local offsetX = draw.SimpleTextOutlined(textPart1, "Trebuchet24", textX, yPos+textOffset, fgColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, bgColor)
			offsetX = offsetX + draw.SimpleTextOutlined(attributed, "Trebuchet24", textX+offsetX, yPos+textOffset, fgColor2, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, bgColor)
			draw.SimpleTextOutlined(textPart2, "Trebuchet24", textX+offsetX, yPos+textOffset, fgColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, bgColor)
			textOffset = textOffset + 24
		end
	end
end)

hook.Add("AddToolMenuTabs","RotgB",function()
	spawnmenu.AddToolTab("RotgB")
end)

hook.Add("AddToolMenuCategories","RotgB",function()
	spawnmenu.AddToolCategory("RotgB","Client","Client")
	spawnmenu.AddToolCategory("RotgB","Server","Server")
end)

--[[local order = {
	"gballoon_red",
	"gballoon_blue",
	"gballoon_green",
	"gballoon_yellow",
	"gballoon_pink",
	"gballoon_white",
	"gballoon_black",
	"gballoon_purple",
	"gballoon_orange",
	"gballoon_gray",
	"gballoon_zebra",
	"gballoon_aqua",
	"gballoon_error",
	"gballoon_rainbow",
	"gballoon_ceramic",
	"gballoon_blimp_blue",
	"gballoon_brick",
	"gballoon_blimp_red",
	"gballoon_marble",
	"gballoon_blimp_green",
	"gballoon_blimp_gray",
	"gballoon_blimp_purple",
	"gballoon_blimp_magenta",
	"gballoon_blimp_rainbow",
}

local function AddBalloon(CategoryList,class)
	local npcprops = list.GetForEdit("NPC")[class]
	local cvals = npcprops.KeyValues
	local Category = CategoryList:Add(npcprops.Name)
	Category:SetHeight(256)
	local Label = vgui.Create("RichText",Category)
	local hasimms,haspops
	Label:Dock(FILL)
	Label:SetText("")
	Label:InsertColorChange(255,127,127,255)
	Label:AppendText("Health: "..(cvals.BalloonHealth or 1))
	Label:InsertColorChange(255,255,127,255)
	Label:AppendText("\nRgBE: "..baseclass.Get("gballoon_base").rotgb_rbetab[class])
	Label:InsertColorChange(127,255,127,255)
	Label:AppendText("\nSize: "..(cvals.BalloonScale or 1))
	Label:InsertColorChange(127,255,255,255)
	Label:AppendText("\nSpeed: "..(cvals.BalloonMoveSpeed or 100))
	Label:InsertColorChange(127,127,255,255)
	Label:AppendText("\nOn pop, spawns the following:")
	for k,v in pairs(baseclass.Get("gballoon_base").rotgb_spawns[class] or {}) do
		local npcprops2 = list.GetForEdit("NPC")[v]
		local h1,s1,v1 = ColorToHSV(string.ToColor(npcprops2.KeyValues.BalloonColor))
		if s1 == 1 then v1 = 1 end
		s1 = s1 / 2
		v1 = (v1 + 1) / 2
		local col2 = HSVToColor(h1,s1,v1)
		Label:InsertColorChange(col2.r,col2.g,col2.b,col2.a)
		Label:AppendText("\n\t"..npcprops2.Name)
		haspops = true
	end
	if not haspops then
		Label:InsertColorChange(255,127,127,255)
		Label:AppendText("\n\tNone")
	end
	Label:InsertColorChange(255,127,255,255)
	Label:AppendText("\nExtra Properties: ")
	if cvals.BalloonWhite then
		Label:InsertColorChange(255,255,255,255)
		Label:AppendText("\n\tFrost Immunity")
		hasimms = true
	end
	if cvals.BalloonBlimp then
		Label:InsertColorChange(255,255,255,255)
		Label:AppendText("\n\tFrost Immunity")
		Label:InsertColorChange(255,255,127,255)
		Label:AppendText("\n\tGlue Immunity")
		hasimms = true
	end
	if cvals.BalloonBlack then
		Label:InsertColorChange(127,127,127,255)
		Label:AppendText("\n\tExplosion Immunity")
		hasimms = true
	end
	if cvals.BalloonPurple then
		Label:InsertColorChange(191,127,255,255)
		Label:AppendText("\n\tMagic Immunity")
		hasimms = true
	end
	if cvals.BalloonGray then
		Label:InsertColorChange(191,191,191,255)
		Label:AppendText("\n\tBullet Immunity")
		hasimms = true
	end
	if cvals.BalloonAqua then
		Label:InsertColorChange(127,255,255,255)
		Label:AppendText("\n\tMelee Immunity")
		hasimms = true
	end
	if cvals.BalloonArmor then
		Label:InsertColorChange(255,127,255,255)
		Label:AppendText("\n\tIgnores damage < "..cvals.BalloonArmor.." layers")
		hasimms = true
	end
	if not hasimms then
		Label:InsertColorChange(255,127,127,255)
		Label:AppendText("\n\tNone")
	end
	function Label:PerformLayout()
		self:SetBGColor(63,63,63,255)
	end
	Category:DoExpansion(false)
end]]

hook.Add("PopulateToolMenu","RotgB",function()
	spawnmenu.AddToolMenuOption("RotgB","Server","RotgB_Server1","Cash","","",function(DForm)
		DForm:TextEntry("Cash Value","rotgb_cash_param")
		DForm:Help(" - "..GetConVar("rotgb_cash_param"):GetHelpText().."\n")
		DForm:Button("Set Cash","rotgb_setcash","*")
		DForm:Button("Add Cash","rotgb_addcash","*")
		DForm:Button("Subtract Cash","rotgb_subcash","*")
		DForm:Help("Preset Values:")
		DForm:Button("Set Value to 0","rotgb_cash_param_internal","0")
		DForm:Button("Set Value to 650","rotgb_cash_param_internal","650")
		DForm:Button("Set Value to 850","rotgb_cash_param_internal","850")
		DForm:Button("Set Value to 20000","rotgb_cash_param_internal","20000")
		DForm:Button("Set Value to ∞","rotgb_cash_param_internal","0x1p128")
		DForm:Help("You can use the ConCommmands rotgb_setcash, rotgb_addcash and rotgb_subcash to modify the cash value.\n")
		DForm:NumSlider("Cash Multiplier","rotgb_cash_mul",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_cash_mul"):GetHelpText().."\n")
		DForm:CheckBox("Split Cash Between Players","rotgb_individualcash")
		DForm:Help(" - "..GetConVar("rotgb_individualcash"):GetHelpText().."\n")
		DForm:NumSlider("Starting Cash","rotgb_starting_cash",0,1000,0)
		DForm:Help(" - "..GetConVar("rotgb_starting_cash"):GetHelpText().."\n")
	end)
	spawnmenu.AddToolMenuOption("RotgB","Server","RotgB_Server2","gBalloons","","",function(DForm)
		DForm:NumSlider("Fire Damage Delay","rotgb_fire_delay",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_fire_delay"):GetHelpText().."\n")
		DForm:NumSlider("Regen Delay","rotgb_regen_delay",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_regen_delay"):GetHelpText().."\n")
		DForm:NumSlider("Rainbow Rate","rotgb_rainbow_gblimp_regen_rate",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_rainbow_gblimp_regen_rate"):GetHelpText().."\n")
		DForm:NumSlider("gBalloon Scale","rotgb_scale",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_scale"):GetHelpText().."\n")
		DForm:NumSlider("Speed Multiplier","rotgb_speed_mul",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_speed_mul"):GetHelpText().."\n")
		DForm:NumSlider("Health Multiplier","rotgb_health_multiplier",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_health_multiplier"):GetHelpText().."\n")
		DForm:NumSlider("Blimp Health Multiplier","rotgb_blimp_health_multiplier",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_blimp_health_multiplier"):GetHelpText().."\n")
		DForm:NumSlider("Aff. Damage Multiplier","rotgb_afflicted_damage_multiplier",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_afflicted_damage_multiplier"):GetHelpText().."\n")
		DForm:CheckBox("Ignore Damage Resistances","rotgb_ignore_damage_resistances")
		DForm:Help(" - "..GetConVar("rotgb_ignore_damage_resistances"):GetHelpText().."\n")
		DForm:CheckBox("Trigger On Kill Effects","rotgb_use_kill_handler")
		DForm:Help(" - "..GetConVar("rotgb_use_kill_handler"):GetHelpText().."\n")
		DForm:CheckBox("Trigger Achievements","rotgb_use_achievement_handler")
		DForm:Help(" - "..GetConVar("rotgb_use_achievement_handler"):GetHelpText().."\n")
		DForm:CheckBox("Use Legacy Models","rotgb_legacy_gballoons")
		DForm:Help(" - "..GetConVar("rotgb_legacy_gballoons"):GetHelpText().."\n")
		DForm:CheckBox("Pertain New Model Effects","rotgb_pertain_effects")
		DForm:Help(" - "..GetConVar("rotgb_pertain_effects"):GetHelpText().."\n")
		DForm:NumSlider("Blood Effect","rotgb_bloodtype",-1,16,0)
		DForm:Help(" - "..GetConVar("rotgb_bloodtype"):GetHelpText().."\n")
		DForm:TextEntry("Blood Decal","rotgb_blooddecal")
		DForm:Help(" - "..GetConVar("rotgb_blooddecal"):GetHelpText().."\n")
		DForm:Button("Blacklist Editor (Admin Only)","rotgb_blacklist")
	end)
	spawnmenu.AddToolMenuOption("RotgB","Server","RotgB_Server3","gBalloon Spawners + Targets","","",function(DForm)
		DForm:NumSlider("Default First Wave","rotgb_default_first_wave",1,1000,0)
		DForm:Help(" - "..GetConVar("rotgb_default_first_wave"):GetHelpText().."\n")
		DForm:NumSlider("Default Last Wave","rotgb_default_last_wave",1,1000,0)
		DForm:Help(" - "..GetConVar("rotgb_default_last_wave"):GetHelpText().."\n")
		DForm:CheckBox("Enable Freeplay","rotgb_freeplay")
		DForm:Help(" - "..GetConVar("rotgb_freeplay"):GetHelpText().."\n")
		DForm:TextEntry("Default Wave Preset","rotgb_default_wave_preset")
		DForm:Help(" - "..GetConVar("rotgb_default_wave_preset"):GetHelpText().."\n")
		DForm:NumSlider("Target Health Override","rotgb_target_health_override",0,1000,0)
		DForm:Help(" - "..GetConVar("rotgb_target_health_override"):GetHelpText().."\n")
		DForm:Button("Wave Editor","rotgb_waveeditor")
	end)
	spawnmenu.AddToolMenuOption("RotgB","Server","RotgB_Server4","AI","","",function(DForm)
		DForm:CheckBox("Custom Pathfinding","rotgb_use_custom_pathfinding")
		DForm:Help(" - "..GetConVar("rotgb_use_custom_pathfinding"):GetHelpText().."\n")
		--[[DForm:CheckBox("Custom AI","rotgb_use_custom_ai")
		DForm:Help(" - "..GetConVar("rotgb_use_custom_ai"):GetHelpText().."\n")]]
		DForm:NumSlider("Targets","rotgb_target_choice",-1,511,0)
		DForm:Help(" - "..GetConVar("rotgb_target_choice"):GetHelpText().."\n")
		DForm:NumberWang("Target Sorting","rotgb_target_sort",-1,3)
		DForm:Help(" - "..GetConVar("rotgb_target_sort"):GetHelpText().."\n")
		DForm:NumSlider("Search Size","rotgb_search_size",-1,2048,0)
		DForm:Help(" - "..GetConVar("rotgb_search_size"):GetHelpText().."\n")
		DForm:NumSlider("Tolerance","rotgb_target_tolerance",0,1000,1)
		DForm:Help(" - "..GetConVar("rotgb_target_tolerance"):GetHelpText().."\n")
		DForm:NumSlider("Pop On Contact","rotgb_pop_on_contact",-2,511,0)
		DForm:Help(" - "..GetConVar("rotgb_pop_on_contact"):GetHelpText().."\n")
		DForm:NumSlider("MinLookAheadDistance","rotgb_setminlookaheaddistance",0,1000,1)
		DForm:Help(" - "..GetConVar("rotgb_setminlookaheaddistance"):GetHelpText().."\n")
		DForm:NumSlider("func_nav_* Tolerance","rotgb_func_nav_expand",0,100,2)
		DForm:Help(" - "..GetConVar("rotgb_func_nav_expand"):GetHelpText().."\n")
	end)
	spawnmenu.AddToolMenuOption("RotgB","Server","RotgB_Server5","Towers","","",function(DForm)
		DForm:CheckBox("Ignore Upgrade Limits","rotgb_ignore_upgrade_limits")
		DForm:Help(" - "..GetConVar("rotgb_ignore_upgrade_limits"):GetHelpText().."\n")
		DForm:NumSlider("Difficulty","rotgb_difficulty",0,3,0)
		DForm:Help(" - "..GetConVar("rotgb_difficulty"):GetHelpText().."\n")
		DForm:NumSlider("Damage Multiplier","rotgb_damage_multiplier",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_damage_multiplier"):GetHelpText().."\n")
		DForm:NumSlider("Range Multiplier","rotgb_tower_range_multiplier",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_tower_range_multiplier"):GetHelpText().."\n")
		DForm:NumSlider("Income Multiplier","rotgb_tower_income_mul",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_tower_income_mul"):GetHelpText().."\n")
	end)
	spawnmenu.AddToolMenuOption("RotgB","Server","RotgB_Server6","Optimization","","",function(DForm)
		DForm:CheckBox("No gBalloon Trails","rotgb_notrails")
		DForm:Help(" - "..GetConVar("rotgb_notrails"):GetHelpText().."\n")
		DForm:NumSlider("Max gBalloons","rotgb_max_to_exist",0,1024,0)
		DForm:Help(" - "..GetConVar("rotgb_max_to_exist"):GetHelpText().."\n")
		DForm:NumSlider("Max Pop Effects/Second","rotgb_max_effects_per_second",0,100,2)
		DForm:Help(" - "..GetConVar("rotgb_max_effects_per_second"):GetHelpText().."\n")
		DForm:NumSlider("Resist Effect Delay","rotgb_resist_effect_delay",-1,10,3)
		DForm:Help(" - "..GetConVar("rotgb_resist_effect_delay"):GetHelpText().."\n")
		DForm:NumSlider("Critical Effect Delay","rotgb_crit_effect_delay",-1,10,3)
		DForm:Help(" - "..GetConVar("rotgb_crit_effect_delay"):GetHelpText().."\n")
		DForm:NumSlider("Path Computation Delay","rotgb_path_delay",0,100,2)
		DForm:Help(" - "..GetConVar("rotgb_path_delay"):GetHelpText().."\n")
		DForm:NumSlider("Max Towers","rotgb_tower_maxcount",-1,64,0)
		DForm:Help(" - "..GetConVar("rotgb_tower_maxcount"):GetHelpText().."\n")
		DForm:NumSlider("Initialization Rate","rotgb_init_rate",-1,100,2)
		DForm:Help(" - "..GetConVar("rotgb_init_rate"):GetHelpText().."\n")
	end)
	spawnmenu.AddToolMenuOption("RotgB","Server","RotgB_Server7","Miscellaneous","","",function(DForm)
		DForm:NumSlider("gBalloon Visual Scale","rotgb_visual_scale",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_visual_scale"):GetHelpText().."\n")
		DForm:ControlHelp("Addon not working as intended?")
		local dangerbutton = DForm:Button("Set All ConVars To Default","rotgb_reset_convars")
		dangerbutton:SetTextColor(Color(255,0,0))
		local DTextEntry = DForm:TextEntry("Debug Parameters","rotgb_debug")
		function DTextEntry:GetAutoComplete(text)
			local dbags = baseclass.Get("gballoon_base").DebugArgs
			local last = string.match(text,"[%w_]+$") or ""
			if last==text then
				text=""
			else
				text = text:sub(1,-#last-1)
			end
			local adctab = {}
			for i,v in ipairs(dbags) do
				if string.find(v,"^"..last) and not string.match(text," ?"..v.." ?") then
					table.insert(adctab,text..v)
				end
			end
			return adctab
		end
		DForm:Help(" - "..GetConVar("rotgb_debug"):GetHelpText().."\n")
	end)
	spawnmenu.AddToolMenuOption("RotgB","Client","RotgB_Client","Options","","",function(DForm)
		DForm:Help("") --whitespace
		DForm:ControlHelp("Cash Display")
		DForm:CheckBox("Enable HUD Display","rotgb_hud_enabled")
		DForm:Help(" - "..ConE:GetHelpText().."\n")
		DForm:NumSlider("X-Position","rotgb_hud_x",0,1,3)
		DForm:Help(" - "..ConX:GetHelpText().."\n")
		DForm:NumSlider("Y-Position","rotgb_hud_y",0,1,3)
		DForm:Help(" - "..ConY:GetHelpText().."\n")
		DForm:NumSlider("HUD Size","rotgb_hud_size",0,128,0)
		DForm:Help(" - "..ConS:GetHelpText().."\n")
		DForm:Help("") --whitespace
		DForm:ControlHelp("Tower Ranges")
		DForm:CheckBox("Show Tower Ranges","rotgb_range_enable_indicators")
		DForm:Help(" - "..GetConVar("rotgb_range_enable_indicators"):GetHelpText().."\n")
		DForm:NumSlider("Hold Time","rotgb_range_hold_time",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_range_hold_time"):GetHelpText().."\n")
		DForm:NumSlider("Fade Time","rotgb_range_fade_time",0,10,3)
		DForm:Help(" - "..GetConVar("rotgb_range_fade_time"):GetHelpText().."\n")
		DForm:NumSlider("Visibility","rotgb_range_alpha",0,255,0)
		DForm:Help(" - "..GetConVar("rotgb_range_alpha"):GetHelpText().."\n")
		DForm:Help("") --whitespace
		DForm:ControlHelp("Other")
		DForm:NumSlider("Circle Side Count","rotgb_circle_segments",3,200,0)
		DForm:Help(" - "..ConQ:GetHelpText().."\n")
		DForm:NumSlider("Text Hover Distance","rotgb_hoverover_distance",0,100,1)
		DForm:Help(" - "..ConH:GetHelpText().."\n")
		DForm:CheckBox("Enable Freeze Effect","rotgb_freeze_effect")
		DForm:Help(" - "..ConF:GetHelpText().."\n")
		DForm:CheckBox("Disable Halo Effects","rotgb_no_glow")
		DForm:Help(" - "..ConG:GetHelpText().."\n")
	end)
	--[[spawnmenu.AddToolMenuOption("Options","RotgB","RotgB_Bestiary","Bestiary","","",function(DForm) -- Add panel
		local CategoryList = vgui.Create("DCategoryList",DForm)
		for i,v in ipairs(order) do
			AddBalloon(CategoryList,v)
		end
		CategoryList:SetHeight(768)
		CategoryList:Dock(FILL)
		DForm:AddItem(CategoryList)
	end)]]
	spawnmenu.AddToolMenuOption("Options","RotgB","RotgB_NavEditorTool","#tool.nav_editor_rotgb.name",game.SinglePlayer() and "gmod_tool nav_editor_rotgb" or "","",function(form)
		if game.SinglePlayer() then
			form:Help("#tool.nav_editor_rotgb.desc")
			local label = form:Help("This tool is only available in single player.")
			label:SetTextColor(Color(255,0,0))
			form:ControlHelp("NOTE: You can also mark the area to be avoided using the Easy Navmesh Editor by adding the AVOID attribute.")
			form:Button("Equip the Easy Navmesh Editor (if available)","gmod_tool","rb655_easy_navedit")
			local Button = form:Button("Get The Easy Navmesh Editor On Workshop")
			Button.DoClick = function() gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=527885257") end
		else
			local label = form:Help("This tool is only available in single player.")
			label:SetTextColor(Color(255,0,0))
		end
	end)
	spawnmenu.AddToolMenuOption("Options","RotgB","RotgB_WaypointEditorTool","#tool.waypoint_editor_rotgb.name","gmod_tool waypoint_editor_rotgb","",function(form)
		form:Help("#tool.waypoint_editor_rotgb.desc")
		form:CheckBox("Teleport Instantly","waypoint_editor_rotgb_teleport")
		form:NumSlider("Weight","waypoint_editor_rotgb_weight",0,100,0)
		form:Help("gBalloon Targets with higher weights are targeted first if the gBalloons do not have a target.")
		form:Help("If weighted targets are linked up, gBalloons are divided among the targets based on their weights.")
		form:Help("If all linked targets have a weight of 0, gBalloons will randomly pick one of the targets.")
		form:CheckBox("Always Show Paths","waypoint_editor_rotgb_indicator_always")
		local choicelist = form:ComboBox("Path Sprite","waypoint_editor_rotgb_indicator_effect")
		choicelist:SetSortItems(false)
		choicelist:AddChoice("Glow","sprites/glow04_noz")
		choicelist:AddChoice("Glow 2","sprites/light_ignorez")
		choicelist:AddChoice("PhysGun Glow","sprites/physg_glow1")
		choicelist:AddChoice("PhysGun Glow 2","sprites/physg_glow2")
		choicelist:AddChoice("Comic Balls","sprites/sent_ball")
		choicelist:AddChoice("Rings","effects/select_ring")
		choicelist:AddChoice("Crosses","effects/select_dot")
		choicelist:AddChoice("Circled Crosses","gui/close_32")
		choicelist:AddChoice("Circled Crosses 2","icon16/circlecross.png")
		choicelist:AddChoice("Cogs","gui/progress_cog.png")
		form:NumSlider("Sprite Scale","waypoint_editor_rotgb_indicator_scale",0,10)
		form:NumSlider("Sprite Speed","waypoint_editor_rotgb_indicator_speed",0.1,10)
		form:CheckBox("Target-to-Target Sprite Bounce","waypoint_editor_rotgb_indicator_bounce")
		choicelist = form:ComboBox("Path Colour","waypoint_editor_rotgb_indicator_color")
		choicelist:AddChoice("Rainbow",0)
		choicelist:AddChoice("Rainbow (Fade In Out)",1)
		choicelist:AddChoice("Rainbow (Fade Middle)",2)
		choicelist:AddChoice("Solid",3)
		choicelist:AddChoice("Solid (Fade In Out)",4)
		choicelist:AddChoice("Solid (Fade Middle)",5)
		choicelist:AddChoice("Rainbow, Solid for Blimps",6)
		choicelist:AddChoice("Rainbow, Solid for Blimps (Fade In Out)",7)
		choicelist:AddChoice("Rainbow, Solid for Blimps (Fade Middle)",8)
		choicelist:AddChoice("Solid, Rainbow for Blimps",9)
		choicelist:AddChoice("Solid, Rainbow for Blimps (Fade In Out)",10)
		choicelist:AddChoice("Solid, Rainbow for Blimps (Fade Middle)",11)
		local mixer = vgui.Create("DColorMixer")
		mixer:SetLabel("Solid Colour")
		mixer:SetConVarR("waypoint_editor_rotgb_indicator_r")
		mixer:SetConVarG("waypoint_editor_rotgb_indicator_g")
		mixer:SetConVarB("waypoint_editor_rotgb_indicator_b")
		mixer:SetConVarA("waypoint_editor_rotgb_indicator_a")
		form:AddItem(mixer)
		mixer = vgui.Create("DColorMixer")
		mixer:SetLabel("Solid Colour for Blimps")
		mixer:SetConVarR("waypoint_editor_rotgb_indicator_boss_r")
		mixer:SetConVarG("waypoint_editor_rotgb_indicator_boss_g")
		mixer:SetConVarB("waypoint_editor_rotgb_indicator_boss_b")
		mixer:SetConVarA("waypoint_editor_rotgb_indicator_boss_a")
		form:AddItem(mixer)
	end)
end)

end -- END CLIENT

function ENT:SetupDataTables()
	self:NetworkVar("Bool",0,"GBOnly",{KeyName="gballoon_damage_only",Edit={title="Only gBalloon Damage",type="Boolean"}})
	self:NetworkVar("Bool",1,"IsBeacon",{KeyName="is_beacon",Edit={title="Is Waypoint",type="Boolean"}})
	self:NetworkVar("Bool",2,"Teleport",{KeyName="teleport_to",Edit={title="Teleport Here",type="Boolean"}})
	self:NetworkVar("Bool",3,"UnSpectatable")
	self:NetworkVar("Bool",4,"NonVital")
	self:NetworkVar("Bool",5,"HideHealth")
	self:NetworkVar("Int",0,"Weight",{KeyName="weight",Edit={title="Weight (highest = first)",type="Int",min=0,max=100}})
	self:NetworkVar("Entity",0,"NextTarget1")
	self:NetworkVar("Entity",1,"NextTarget2")
	self:NetworkVar("Entity",2,"NextTarget3")
	self:NetworkVar("Entity",3,"NextTarget4")
	self:NetworkVar("Entity",4,"NextTarget5")
	self:NetworkVar("Entity",5,"NextTarget6")
	self:NetworkVar("Entity",6,"NextTarget7")
	self:NetworkVar("Entity",7,"NextTarget8")
	self:NetworkVar("Entity",8,"NextTarget9")
	self:NetworkVar("Entity",9,"NextTarget10")
	self:NetworkVar("Entity",10,"NextTarget11")
	self:NetworkVar("Entity",11,"NextTarget12")
	self:NetworkVar("Entity",12,"NextTarget13")
	self:NetworkVar("Entity",13,"NextTarget14")
	self:NetworkVar("Entity",14,"NextTarget15")
	self:NetworkVar("Entity",15,"NextTarget16")
	self:NetworkVar("Entity",16,"NextBlimpTarget1")
	self:NetworkVar("Entity",17,"NextBlimpTarget2")
	self:NetworkVar("Entity",18,"NextBlimpTarget3")
	self:NetworkVar("Entity",19,"NextBlimpTarget4")
	self:NetworkVar("Entity",20,"NextBlimpTarget5")
	self:NetworkVar("Entity",21,"NextBlimpTarget6")
	self:NetworkVar("Entity",22,"NextBlimpTarget7")
	self:NetworkVar("Entity",23,"NextBlimpTarget8")
	self:NetworkVar("Entity",24,"NextBlimpTarget9")
	self:NetworkVar("Entity",25,"NextBlimpTarget10")
	self:NetworkVar("Entity",26,"NextBlimpTarget11")
	self:NetworkVar("Entity",27,"NextBlimpTarget12")
	self:NetworkVar("Entity",28,"NextBlimpTarget13")
	self:NetworkVar("Entity",29,"NextBlimpTarget14")
	self:NetworkVar("Entity",30,"NextBlimpTarget15")
	self:NetworkVar("Entity",31,"NextBlimpTarget16")
end

function ENT:KeyValue(key,value)
	local lkey = key:lower()
	if lkey=="gballoon_damage_only" then
		self:SetGBOnly(tobool(value))
	elseif lkey=="model" then
		self.Model = value
	elseif lkey=="skin" then
		self.Skin = value
	elseif lkey=="is_beacon" then
		self:SetIsBeacon(tobool(value))
	elseif string.sub(lkey,1,11) == "next_target" then
		local num = (tonumber("0x"..string.sub(lkey,-1)) or 0) + 1
		self.TempNextTargets = self.TempNextTargets or {}
		self.TempNextTargets[num] = value
	elseif string.sub(lkey,1,17) == "next_blimp_target" then
		local num = (tonumber("0x"..string.sub(lkey,-1)) or 0) + 1
		self.TempNextBlimpTargets = self.TempNextBlimpTargets or {}
		self.TempNextBlimpTargets[num] = value
	elseif lkey=="is_visible" then
		self.TempIsHidden = not tobool(value)
	elseif lkey=="teleport_to" then
		self:SetTeleport(tobool(value))
	elseif lkey=="unspectatable" then
		self:SetUnSpectatable(tobool(value))
		scripted_ents.GetMember("point_rotgb_spectator", "TransmitChangeToSpectatingPlayers")(self)
	elseif lkey=="non_vital" then
		self:SetNonVital(tobool(value))
	elseif lkey=="hide_health" then
		self:SetHideHealth(tobool(value))
	elseif lkey=="weight" then
		self:SetWeight(tonumber(value) or 0)
	elseif lkey=="onbreak" then
		self:StoreOutput(key,value)
	elseif lkey=="onhealthchanged" then
		self:StoreOutput(key,value)
	elseif lkey=="onkilled" then
		self:StoreOutput(key,value)
	elseif lkey=="ontakedamage" then
		self:StoreOutput(key,value)
	elseif lkey=="onwaypointed" then
		self:StoreOutput(key,value)
	elseif lkey=="onwaypointedblimp" then
		self:StoreOutput(key,value)
	elseif lkey=="onwaypointednonblimp" then
		self:StoreOutput(key,value)
	end
end

function ENT:AcceptInput(input,activator,caller,data)
	input = input:lower()
	if input=="sethealth" then
		local oldhealth = self:Health()
		self:SetHealth(tonumber(data) or 0)
		if self:Health()~=oldhealth then
			self:TriggerOutput("OnHealthChanged",activator,self:Health()/self:GetMaxHealth())
		end
		if self:Health()<=0 then
			self:TriggerOutput("OnBreak",activator)
			self:Input("Kill",activator,self,data)
		end
	elseif input=="addhealth" then
		local oldhealth = self:Health()
		self:SetHealth(self:Health()+(tonumber(data) or 0))
		if self:Health()~=oldhealth then
			self:TriggerOutput("OnHealthChanged",activator,self:Health()/self:GetMaxHealth())
		end
	elseif input=="removehealth" then
		local oldhealth = self:Health()
		self:SetHealth(self:Health()-(tonumber(data) or 0))
		if self:Health()~=oldhealth then
			self:TriggerOutput("OnHealthChanged",activator,self:Health()/self:GetMaxHealth())
		end
		if self:Health()<=0 then
			self:TriggerOutput("OnBreak",activator)
			self:Input("Kill",activator,self,data)
		end
	elseif input=="setmaxhealth" then
		self:SetMaxHealth(tonumber(data) or 0)
	elseif input=="addmaxhealth" then
		self:SetMaxHealth(self:GetMaxHealth()+(tonumber(data) or 0))
	elseif input=="removemaxhealth" then
		self:SetMaxHealth(self:GetMaxHealth()-(tonumber(data) or 0))
	elseif input=="break" then
		local oldhealth = self:Health()
		self:SetHealth(0)
		if self:Health()~=oldhealth then
			self:TriggerOutput("OnHealthChanged",activator,self:Health()/self:GetMaxHealth())
		end
		self:TriggerOutput("OnBreak",activator)
		self:Input("Kill",activator,self,data)
	elseif input=="setiswaypoint" then
		self:SetIsBeacon(tobool(data))
	elseif string.sub(input,1,15) == "setnextwaypoint" then
		local num = (tonumber("0x"..string.sub(input,-1)) or 0) + 1
		self["SetNextTarget"..num](self,data~="" and ents.FindByName(data)[1] or NULL)
	elseif string.sub(input,1,20) == "setnextblimpwaypoint" then
		local num = (tonumber("0x"..string.sub(input,-1)) or 0) + 1
		self["SetNextBlimpTarget"..num](self,data~="" and ents.FindByName(data)[1] or NULL)
	elseif input=="setweight" then
		self:SetWeight(tonumber(data) or 0)
	elseif input=="enablespectating" then
		self:SetUnSpectatable(false)
	elseif input=="disablespectating" then
		self:SetUnSpectatable(true)
		scripted_ents.GetMember("point_rotgb_spectator", "TransmitChangeToSpectatingPlayers")(self)
	elseif input=="togglespectating" then
		self:SetUnSpectatable(not self:GetUnSpectatable())
		scripted_ents.GetMember("point_rotgb_spectator", "TransmitChangeToSpectatingPlayers")(self)
	elseif input=="enablevitaltarget" then
		self:SetNonVital(false)
	elseif input=="disablevitaltarget" then
		self:SetNonVital(true)
	elseif input=="togglevitaltarget" then
		self:SetNonVital(not self:GetNonVital())
	elseif input=="enablehealthhide" then
		self:SetHideHealth(true)
	elseif input=="disablehealthhide" then
		self:SetHideHealth(false)
	elseif input=="togglehealthhide" then
		self:SetHideHealth(not self:GetHideHealth())
	end
end

function ENT:SpawnFunction(ply,trace,classname)
	if not trace.Hit then return end
	
	local ent = ents.Create(classname)
	ent:SetPos(trace.HitPos+trace.HitNormal*5)
	ent:Spawn()
	ent:Activate()
	
	return ent
end

function ENT:Initialize()
	if SERVER then
		self:SetModel(self.Model or "models/props_c17/streetsign004e.mdl")
		if self.Skin then
			self:SetSkin(self.Skin)
		end
		self:PhysicsInit(SOLID_VPHYSICS)
		local physobj = self:GetPhysicsObject()
		if IsValid(physobj) then
			physobj:Wake()
		end
		local healthOverride = GetConVar("rotgb_target_health_override"):GetInt()
		if healthOverride > 0 then
			self:SetHealth(healthOverride)
			self:SetMaxHealth(healthOverride)
		elseif self.CurHealth then
			self:SetHealth(self.CurHealth)
			self:SetMaxHealth(self.CurMaxHealth)
		end
		--[[if self.TmepNextTarget then
			self:SetNextTarget(ents.FindByName(self.TmepNextTarget)[1] or NULL)
			self.TmepNextTarget = nil
		end
		if IsValid(self:GetNextTarget()) then
			self:SetNextTarget1(self:GetNextTarget())
			self:SetNextTarget(NULL)
		end]]
		if self.TempNextTargets then
			for k,v in pairs(self.TempNextTargets) do
				self["SetNextTarget"..k](self,v~="" and ents.FindByName(v)[1] or NULL)
			end
		end
		if self.TempNextBlimpTargets then
			for k,v in pairs(self.TempNextBlimpTargets) do
				self["SetNextBlimpTarget"..k](self,v~="" and ents.FindByName(v)[1] or NULL)
			end
		end
		if self.TempIsHidden then
			self:SetNotSolid(true)
			self:SetNoDraw(true)
			self:SetMoveType(MOVETYPE_NOCLIP)
		end
	end
end

function ENT:PreEntityCopy()
	self.CurHealth = self:Health()
	self.CurMaxHealth = self:GetMaxHealth()
end

function ENT:PostEntityPaste(ply,ent,tab)
	ent:Spawn()
	ent:Activate()
end

function ENT:OnTakeDamage(dmginfo)
	self:TriggerOutput("OnTakeDamage",dmginfo:GetAttacker(),dmginfo:GetDamage())
	if not self:GetGBOnly() or (IsValid(dmginfo:GetAttacker()) and dmginfo:GetAttacker():GetClass()=="gballoon_base") then
		self:EmitSound("physics/metal/metal_box_break"..math.random(1,2)..".wav",60)
		local oldHealth = self:Health()
		self:SetHealth(oldHealth-dmginfo:GetDamage())
		if oldHealth~=self:Health() then
			local attacker = dmginfo:GetAttacker()
			local flags = bit.bor(
				IsValid(attacker) and attacker:GetClass()=="gballoon_base" and 1 or 0,
				attacker:IsPlayer() and 2 or 0
			)
			if bit.band(flags, 1)==1 then
				flags = bit.bor(
					flags,
					attacker:GetBalloonProperty("BalloonFast") and 4 or 0,
					attacker:GetBalloonProperty("BalloonHidden") and 8 or 0,
					attacker:GetBalloonProperty("BalloonDoRegen") and 16 or 0,
					attacker:GetBalloonProperty("BalloonShielded") and 32 or 0
				)
			end
			local label = bit.band(flags, 2)==2 and attacker:UserID() or bit.band(flags, 1)==1 and attacker:GetBalloonProperty("BalloonType") or IsValid(attacker) and attacker:GetClass() or "<unknown>"
			net.Start("rotgb_target_received_damage")
			net.WriteEntity(self)
			net.WriteInt(self:Health(), 32)
			net.WriteString(label)
			net.WriteInt(oldHealth-self:Health(), 32)
			net.WriteUInt(flags, 8)
			net.WriteFloat(CurTime())
			net.Broadcast()
			self:TriggerOutput("OnHealthChanged",dmginfo:GetAttacker(),self:Health()/self:GetMaxHealth())
		end
		if self:Health()<=0 then
			self:TriggerOutput("OnBreak",dmginfo:GetAttacker())
			self:Input("Kill",dmginfo:GetAttacker(),dmginfo:GetInflictor())
		end
	end
end

function ENT:OnRemove()
	if SERVER then
		hook.Run("gBalloonTargetRemoved", self)
		self:TriggerOutput("OnKilled")
	end
end

function ENT:DrawTranslucent()
	--self:Draw()
	if not (self:GetIsBeacon() or self:GetHideHealth()) then
		--self:DrawModel()
		local actualHealth = math.min(self:Health(), self.rotgb_ActualHealth or math.huge)
		local text1 = "Health: "..actualHealth
		surface.SetFont("DermaLarge")
		local t1x,t1y = surface.GetTextSize(text1)
		local reqang = (self:GetPos()-LocalPlayer():GetShootPos()):Angle()
		reqang.p = 0
		reqang.y = reqang.y-90
		reqang.r = 90
		cam.Start3D2D(self:GetPos()+Vector(0,0,ConH:GetFloat()+t1y*0.1+self:OBBMaxs().z),reqang,0.2)
			surface.SetDrawColor(0,0,0,127)
			surface.DrawRect(t1x/-2,t1y/-2,t1x,t1y)
			surface.SetTextColor(HSVToColor(math.Clamp(actualHealth/self:GetMaxHealth()*120,0,120),1,1))
			surface.SetTextPos(t1x/-2,t1y/-2)
			surface.DrawText(text1)
		cam.End3D2D()
	end
end

list.Set("NPC","gballoon_target_100",{
	Name = "100HP gBalloon Target",
	Class = "gballoon_target",
	Category = "RotgB: Miscellaneous",
	KeyValues = {
		health = "100",
		max_health = "100"
	}
})
list.Set("NPC","gballoon_target_150",{
	Name = "150HP gBalloon Target",
	Class = "gballoon_target",
	Category = "RotgB: Miscellaneous",
	KeyValues = {
		health = "150",
		max_health = "150"
	}
})
list.Set("NPC","gballoon_target_200",{
	Name = "200HP gBalloon Target",
	Class = "gballoon_target",
	Category = "RotgB: Miscellaneous",
	KeyValues = {
		health = "200",
		max_health = "200"
	}
})
list.Set("NPC","gballoon_target_050",{
	Name = "50HP gBalloon Target",
	Class = "gballoon_target",
	Category = "RotgB: Miscellaneous",
	KeyValues = {
		health = "50",
		max_health = "50"
	}
})
list.Set("NPC","gballoon_target_op",{
	Name = "999999999HP gBalloon Target",
	Class = "gballoon_target",
	Category = "RotgB: Miscellaneous",
	KeyValues = {
		health = "999999999",
		max_health = "999999999"
	}
})
list.Set("SpawnableEntities","gballoon_target_100",{
	PrintName = "100HP gBalloon Target",
	ClassName = "gballoon_target",
	Category = "RotgB: Miscellaneous",
	KeyValues = {
		health = "100",
		max_health = "100"
	}
})
list.Set("SpawnableEntities","gballoon_target_150",{
	PrintName = "150HP gBalloon Target",
	ClassName = "gballoon_target",
	Category = "RotgB: Miscellaneous",
	KeyValues = {
		health = "150",
		max_health = "150"
	}
})
list.Set("SpawnableEntities","gballoon_target_200",{
	PrintName = "200HP gBalloon Target",
	ClassName = "gballoon_target",
	Category = "RotgB: Miscellaneous",
	KeyValues = {
		health = "200",
		max_health = "200"
	}
})
list.Set("SpawnableEntities","gballoon_target_050",{
	PrintName = "50HP gBalloon Target",
	ClassName = "gballoon_target",
	Category = "RotgB: Miscellaneous",
	KeyValues = {
		health = "50",
		max_health = "50"
	}
})
list.Set("SpawnableEntities","gballoon_target_op",{
	PrintName = "999999999HP gBalloon Target",
	ClassName = "gballoon_target",
	Category = "RotgB: Miscellaneous",
	KeyValues = {
		health = "999999999",
		max_health = "999999999"
	}
})