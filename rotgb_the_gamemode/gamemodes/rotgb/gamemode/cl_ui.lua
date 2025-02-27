-- real talk, I should probably make an addon to ease the process of making UIs
-- right now there is way too many UI code duplication going on across my addons...
local color_dark_black_doublesemiopaque = Color(0, 0, 0, 223)
local color_gray = Color(127, 127, 127)
local color_gray_semitransparent = Color(127, 127, 127, 63)
local color_light_gray = Color(191, 191, 191)
local color_red = Color(255, 0, 0)
local color_light_red = Color(255, 127, 127)
local color_orange = Color(255, 127, 0)
local color_light_orange = Color(255, 191, 127)
local color_yellow = Color(255, 255, 0)
local color_green = Color(0, 255, 0)
local color_green_semitransparent = Color(0, 255, 0, 63)
local color_light_green = Color(127, 255, 127)
local color_dark_green = Color(0, 127, 0)
local color_aqua = Color(0, 255, 255)
local color_light_blue = Color(127, 127, 255)
local color_purple = Color(127, 0, 255)
local color_magenta = Color(255, 0, 255)
local SQRT_2 = math.sqrt(2)

local SCOREBOARD_CELL_WIDTH_MULTIPLIERS = {1, 6, 6, 3, 3, 9, {1, 3, 2}, 6}
local SCOREBOARD_PADDING = 2
local SCOREBOARD_CELL_SPACE = 1
local SCOREBOARD_FIELDS = {
	"#rotgb_tg.scoreboard.name",
	"#rotgb_tg.scoreboard.current_cash",
	"#rotgb_tg.scoreboard.score",
	"#rotgb_tg.scoreboard.ping",
	"#rotgb_tg.scoreboard.level",
	"#rotgb_tg.scoreboard.transfer",
	"#rotgb_tg.scoreboard.voice",
	"#rotgb_tg.scoreboard.kick"
}
local SCOREBOARD_FUNCS = {
	[2] = function(ply)
		return ROTGB_FormatCash(ROTGB_GetCash(ply))
	end,
	[3] = function(ply)
		return string.Comma(math.floor(ply.rtg_gBalloonPops or 0))
	end,
	[4] = function(ply)
		return ROTGB_LocalizeString("rotgb_tg.scoreboard.ping_ms", string.Comma(ply:Ping()))
	end
}
local SKILL_SIZE = 64
local SKILL_SIZE_HALF = SKILL_SIZE/2
local SKILL_SPRITE_RADIUS_MULTIPLIERS = {0.5,0.5,1.0}
local SKILL_INFO_RADIUS_MULTIPLIER = 0.75
local SKILL_SMOOTH_SIZE_MIN = 0.9
local SKILL_SMOOTH_SIZE_MAX = 1.1
local SKILL_SMOOTH_SPEED_MULTIPLIER = 1
local SKILL_ACTIVATE_TIME = 1
local SKILL_ACTIVATE_SIZE = 2
local SKILL_BEAM_WIDTH_MULTIPLIER = 0.25
local SKILL_BEAM_SPEED_MULTIPLIER = 1
local SKILL_BEAM_SMOOTH_ALPHA_MIN = 127
local SKILL_BEAM_SMOOTH_ALPHA_MAX = 255
local SKILL_TOOLTIP_OFFSET = ScreenScale(3)
local SKILL_TOOLTIP_PADDING = ScreenScale(3)
local SKILL_TOOLTIP_TIERS = {{"#rotgb_tg.skills.perk_0", color_light_green}, {"#rotgb_tg.skills.perk_1", color_light_blue}, {"#rotgb_tg.skills.perk_2", color_light_orange}}
local SKILL_LEFT_TEXTS = {
	{
		-- hardcoded
	},
	{
		color_red, "#rotgb_tg.skills.skill_apply_warning"
	}
}
local CATEGORY_COLORS = {color_green, color_yellow, color_orange, color_red, color_magenta}
local ACHIEVEMENT_PADDING = ScreenScale(2)
local ACHIEVEMENT_SIZE = ScreenScale(48)
local ACHIEVEMENT_TIERS = {color_light_green, color_light_blue, color_light_orange}

local FONT_HEADER_HEIGHT = ScreenScale(16)
local FONT_BODY_HEIGHT = ScreenScale(12)
local FONT_LEVEL_HEIGHT = ScreenScale(16)
local FONT_EXPERIENCE_HEIGHT = ScreenScale(12)
local FONT_SKILL_BODY_HEIGHT = ScreenScale(6)
local FONT_ACHIEVEMENT_HEADER_HEIGHT = ScreenScale(12)
local FONT_ACHIEVEMENT_BODY_HEIGHT = ScreenScale(8)

local FONT_SCOREBOARD_HEADER_HEIGHT = ScreenScale(8)
local FONT_SCOREBOARD_BODY_HEIGHT = ScreenScale(8)
local FONT_LEVEL_SMALL_HEIGHT = ScreenScale(5)

local indentX = ScrW()*0.1
local indentY = ScrH()*0.1

local function CreateSkillMaterial(name, vtf)
	return CreateMaterial(name, "UnlitGeneric", {
		["$basetexture"] = vtf,
		["$vertexcolor"] = 1,
		["$translucent"] = 1,
		["$additive"] = 1,
		["$nolod"] = 1
	})
end
local SKILL_MATERIALS = {
	{
		locked = CreateSkillMaterial("rtg_SkillL1", "sprites/physcannon_blueflare1"),
		unlocked = CreateSkillMaterial("rtg_SkillU1", "sprites/blueflare1"),
		acquired = CreateSkillMaterial("rtg_SkillA1", "sprites/orangeflare1")
	},
	{
		locked = CreateSkillMaterial("rtg_SkillL0", "sprites/physcannon_bluecore2"),
		unlocked = CreateSkillMaterial("rtg_SkillU0", "sprites/physcannon_bluecore2b"),
		acquired = CreateSkillMaterial("rtg_SkillA0", "sprites/orangecore2")
	},
	{
		locked = CreateSkillMaterial("rtg_SkillL2", "sprites/physcannon_bluecore1"),
		unlocked = CreateSkillMaterial("rtg_SkillU2", "sprites/physcannon_bluecore1b"),
		acquired = CreateSkillMaterial("rtg_SkillA2", "sprites/orangecore1")
	},
	beam = CreateSkillMaterial("rtg_SkillBeam", "sprites/laser"),
	info = CreateSkillMaterial("rtg_SkillInfo", "sprites/flare1")
}

AccessorFunc(GM, "StartupMenu", "StartupMenu")
AccessorFunc(GM, "TeamSelectionMenu", "TeamSelectionMenu")
AccessorFunc(GM, "DifficultySelectionMenu", "DifficultySelectionMenu")
AccessorFunc(GM, "VoteMenu", "VoteMenu")
AccessorFunc(GM, "VoterMenu", "VoterMenu")
AccessorFunc(GM, "SkillWebMenu", "SkillWebMenu")
AccessorFunc(GM, "AchievementsMenu", "AchievementsMenu")

surface.CreateFont("rotgb_header", {
	font = "Bombardier Rotgb",
	extended = true,
	size = FONT_HEADER_HEIGHT
})
surface.CreateFont("rotgb_body", {
	font = "Bombardier Rotgb",
	extended = true,
	size = FONT_BODY_HEIGHT
})
surface.CreateFont("rotgb_level", {
	font = "Bombardier Rotgb",
	extended = true,
	size = FONT_LEVEL_HEIGHT
})
surface.CreateFont("rotgb_experience", {
	font = "Bombardier Rotgb",
	extended = true,
	size = FONT_EXPERIENCE_HEIGHT
})
surface.CreateFont("rotgb_scoreboard_header", {
	font = "Bombardier Rotgb",
	extended = true,
	size = FONT_SCOREBOARD_HEADER_HEIGHT
})
surface.CreateFont("rotgb_scoreboard_body", {
	font = "Luckiest Guy Rotgb",
	extended = true,
	size = FONT_SCOREBOARD_BODY_HEIGHT
})
surface.CreateFont("rotgb_level_small", {
	font = "Bombardier Rotgb",
	extended = true,
	size = FONT_LEVEL_SMALL_HEIGHT
})
surface.CreateFont("rotgb_skill_body", {
	font = "Bombardier Rotgb",
	extended = true,
	size = FONT_SKILL_BODY_HEIGHT
})
surface.CreateFont("rotgb_achievement_header", {
	font = "Bombardier Rotgb",
	extended = true,
	size = FONT_ACHIEVEMENT_HEADER_HEIGHT
})
surface.CreateFont("rotgb_achievement_body", {
	font = "Bombardier Rotgb",
	extended = true,
	size = FONT_ACHIEVEMENT_BODY_HEIGHT
})

local function DrawDarkBackground(panel, w, h)
	surface.SetDrawColor(0,0,0,223)
	surface.DrawRect(0,0,w,h)
end

local function DrawDebugBackground(panel, w, h)
	surface.SetDrawColor(255,255,255)
	surface.DrawOutlinedRect(0,0,w,h,1)
	surface.DrawLine(0,0,w,h)
end

local function DrawTextBoxBackground(panel, w, h)
	surface.SetDrawColor(color_dark_black_doublesemiopaque)
	surface.DrawRect(0,0,w,h)
	surface.SetDrawColor(color_white)
	surface.DrawOutlinedRect(0,0,w,h,1)
end

local function CreateMenu()
	local Menu = vgui.Create("DFrame")
	Menu:SetSize(ScrW(), ScrH())
	Menu:SetTitle("")
	Menu:SetDraggable(false)
	Menu:ShowCloseButton(GAMEMODE.DebugMode)
	Menu.Paint = DrawDarkBackground
	Menu:DockPadding(indentX, indentY, indentX, indentY)
	Menu:MakePopup()
	local oldThink = Menu.Think
	
	function Menu:Think(...)
		if oldThink then
			oldThink(self, ...)
		end
		if (self.rtg_RemovalTime or math.huge) < RealTime() then
			self:Close()
		end
	end
	function Menu:RemoveAfterDelay(tim)
		self.rtg_RemovalTime = RealTime() + tim
	end
	
	return Menu
end

local function CreateHeader(parent, zPos, text)
	local HeaderText = vgui.Create("DLabel", parent)
	HeaderText:SetFont("rotgb_header")
	HeaderText:SetText(text)
	HeaderText:SetTextColor(color_white)
	HeaderText:SetZPos(zPos)
	HeaderText:Dock(TOP)
	HeaderText:SetWrap(true)
	HeaderText:SetAutoStretchVertical(true)
	
	return HeaderText
end

local function CreateText(parent, zPos, text)
	local BodyText = vgui.Create("DLabel", parent)
	BodyText:SetFont("rotgb_body")
	BodyText:SetText(text)
	BodyText:SetTextColor(color_white)
	BodyText:SetZPos(zPos)
	BodyText:Dock(TOP)
	BodyText:SetWrap(true)
	BodyText:SetAutoStretchVertical(true)
	
	return BodyText
end

local function CreateElementCenteringPanel(child, parent)
	local Panel = vgui.Create("DPanel", parent)
	Panel:SetTall(child:GetTall())
	Panel.Paint = nil
	child:SetParent(Panel)
	function Panel:PerformLayout(w,h)
		child:CenterHorizontal()
	end
	
	return Panel
end

local function CreateHorizontalPanelContainer(parent, children, gapWidth)
	local Panel = vgui.Create("DPanel", parent)
	Panel.childrenPanels = children or {}
	Panel.gapWidth = gapWidth or 0
	Panel.Paint = nil
	if IsValid(children[1]) then
		local newHeight = children[1]:GetTall()
		Panel:SetTall(newHeight)
		for k,v in pairs(children) do
			v:SetTall(newHeight)
			v:SetParent(Panel)
		end
	end
	function Panel:PerformLayout(w,h)
		local widthRequired = -self.gapWidth
		for k,v in pairs(self.childrenPanels) do
			widthRequired = widthRequired + v:GetWide() + self.gapWidth
		end
		local panelPos = VectorTable((self:GetWide() - widthRequired) / 2, 0)
		for k,v in pairs(self.childrenPanels) do
			v:SetPos(panelPos:Unpack())
			panelPos:AddUnpacked(v:GetWide() + self.gapWidth, 0)
		end
	end
	
	return Panel
end

local function ButtonSetColor(panel, color)
	panel._Color = color
	panel._HoverColor = Color(127.5 + color.r/2, 127.5 + color.g/2, 127.5 + color.b/2)
end

local function ButtonPaintDetermineColor(panel)
	local drawColor = panel._Color or color_white
	if not panel:IsEnabled() then
		drawColor = color_gray
	elseif panel:IsDown() then
		drawColor = color_white
	elseif panel:IsHovered() then
		drawColor = panel._HoverColor or color_white
	end
	
	if panel:GetFlashing() then
		drawColor = LerpColor(math.sin(CurTime()*math.pi)/2+0.5, drawColor, color_white)
	end
	
	if panel:GetTextColor()~=drawColor then
		panel:SetTextColor(drawColor)
	end
	
	return drawColor
end

local function ButtonPaint(panel, w, h)
	local drawColor = ButtonPaintDetermineColor(panel)
	
	draw.RoundedBox(8, 0, 0, w, h, drawColor)
	draw.RoundedBox(8, 4, 4, w-8, h-8, color_black)
end

local function ButtonPaintSmall(panel, w, h)
	local drawColor = ButtonPaintDetermineColor(panel)
	
	draw.RoundedBox(4, 0, 0, w, h, drawColor)
	draw.RoundedBox(4, 2, 2, w-4, h-4, color_black)
end

local function CreateButton(parent, text, color, clickFunc)
	local Button = vgui.Create("DButton", parent)
	Button:SetFont("rotgb_header")
	Button:SetText(text)
	Button:SizeToContentsX(FONT_HEADER_HEIGHT/2)
	Button:SizeToContentsY(FONT_HEADER_HEIGHT/2)
	Button.DoClick = clickFunc
	Button.SetColor = ButtonSetColor
	Button.Paint = ButtonPaint
	AccessorFunc(Button, "Flashing", "Flashing", FORCE_BOOL)
	
	Button:SetColor(color)
	return Button
end

local function CreateTeamLeftPanel()
	local Panel = vgui.Create("DPanel")
	Panel.CurrentTeam = 0
	Panel.Paint = nil
	
	local AllTeams = team.GetAllTeams()
	for k,v in pairs(AllTeams) do
		if k ~= TEAM_CONNECTING and k ~= TEAM_UNASSIGNED then
			local TeamButton = CreateButton(Panel, "#rotgb_tg.team.loading", v.Color, function()
				hook.Run("HideTeam")
				RunConsoleCommand("changeteam", k)
			end)
			function TeamButton:RefreshText()
				local text = ROTGB_LocalizeString(
					"rotgb_tg.buttons.team",
					language.GetPhrase(v.Name),
					string.format("%u", team.NumPlayers(k))
				)
				self:SetText(text)
			end
			function TeamButton:Think()
				-- I'd use PANEL:IsHovered() but apparently there is also DButton.Hovered
				-- I wonder if the class variable exists purely due to code spaghetti though, oh well
				if self.Hovered and Panel.CurrentTeam~=k then
					Panel.CurrentTeam = k
					Panel:OnTeamHovered(Panel.CurrentTeam)
				end
				
				if team.NumPlayers(k) ~= self.TeamNum then
					self.TeamNum = team.NumPlayers(k)
					self:RefreshText()
				end
			end
			TeamButton:Dock(TOP)
			TeamButton:SetZPos(k)
			
			if IsValid(LocalPlayer()) and LocalPlayer():Team()==k then
				TeamButton:SetCursor("no")
				TeamButton:SetEnabled(false)
			end
		end
	end
	
	return Panel
end

local function CreateTeamRightPanel()
	local Panel = vgui.Create("DPanel")
	local Header = CreateHeader(Panel, 1, "")
	local DescriptionPanels = {}
	local teamID = LocalPlayer():Team()
	
	Panel.Paint = nil
	function Panel:OnTeamHovered(teamID)
		for k,v in pairs(DescriptionPanels) do
			v:Remove()
		end
		
		Header:SetText(hook.Run("GetTeamName", teamID))
		for k,v in pairs(TEAM_DESCRIPTIONS[teamID]) do
			table.insert(DescriptionPanels, CreateText(Panel, k+1, v))
		end
	end
	
	return Panel
end

local function CreateScoreboardNameCell(parent, ply)
	local PFPPanel = vgui.Create("DPanel", parent)
	PFPPanel:SetWide(FONT_SCOREBOARD_BODY_HEIGHT)
	PFPPanel:Dock(LEFT)
	PFPPanel.Paint = nil
	
	local avatarSize = FONT_SCOREBOARD_BODY_HEIGHT
	if avatarSize < 184 then
		avatarSize = bit.lshift(1, math.floor(math.log(avatarSize, 2))) 
	else
		avatarSize = 184
	end
	local PFPImage = vgui.Create("AvatarImage", PFPPanel)
	PFPImage:SetSize(avatarSize, avatarSize)
	PFPImage:SetPlayer(ply, avatarSize)
	function PFPPanel:PerformLayout()
		PFPImage:Center()
	end
	
	local NamePanel = vgui.Create("DLabel", parent)
	NamePanel:Dock(FILL)
	NamePanel:SetFont("rotgb_scoreboard_body")
	function NamePanel:Update()
		NamePanel:SetText(ply:Nick())
		NamePanel:SetTextColor(team.GetColor(ply:Team()))
	end
	NamePanel:Update()
	
	return NamePanel
end

local function CreateScoreboardOtherLevelCell(parent, ply)
	local LevelPanel = vgui.Create("DPanel", parent)
	LevelPanel:SetWide(FONT_SCOREBOARD_BODY_HEIGHT*SCOREBOARD_CELL_WIDTH_MULTIPLIERS[1]*SCOREBOARD_CELL_WIDTH_MULTIPLIERS[5])
	LevelPanel:Dock(RIGHT)
	LevelPanel:SetZPos(-5)
	LevelPanel.Level = ply:RTG_GetLevel()
	LevelPanel.LevelFrac = ply:RTG_GetLevelFraction()
	function LevelPanel:Paint(w, h)
		surface.SetFont("rotgb_level_small")
		surface.SetTextPos(0,0)
		surface.SetTextColor(127,0,255)
		surface.DrawText(string.Comma(self.Level))
		
		surface.SetDrawColor(63,0,127)
		surface.DrawRect(0,h*.75,w,h*.25)
		surface.SetDrawColor(127,0,255)
		surface.DrawRect(0,h*.75,w*self.LevelFrac,h*.25)
	end
	function LevelPanel:Update()
		local curXP = math.floor(ply:RTG_GetExperience())
		local neededXP = math.ceil(ply:RTG_GetExperienceNeeded())
		if self.LastCurXP ~= curXP then
			self.LastCurXP = curXP
			self.Level = ply:RTG_GetLevel()
			self.LevelFrac = ply:RTG_GetLevelFraction()
			self:SetTooltip(
				ROTGB_LocalizeString(
					"rotgb_tg.experience",
					string.Comma(curXP),
					string.Comma(neededXP)
				)
			)
		end
	end
	
	return LevelPanel
end

local function CreateScoreboardTransferCell(parent, ply)
	local TransferButton = CreateButton(parent, "$? >", color_green, function()
		-- the code for this is defined in rotgb_general.lua in the main RotgB addon, not in this gamemode
		net.Start("rotgb_generic")
		net.WriteUInt(ROTGB_OPERATION_TRANSFER, 8)
		net.WriteEntity(ply)
		net.SendToServer()
	end)
	
	TransferButton.Paint = ButtonPaintSmall
	TransferButton:SetFont("rotgb_scoreboard_header")
	TransferButton:SetWide(FONT_SCOREBOARD_BODY_HEIGHT*SCOREBOARD_CELL_WIDTH_MULTIPLIERS[1]*SCOREBOARD_CELL_WIDTH_MULTIPLIERS[6])
	TransferButton:Dock(RIGHT)
	TransferButton:SetZPos(-6)
	
	if ply == LocalPlayer() then
		TransferButton:SetCursor("no")
		TransferButton:SetEnabled(false)
	end
	
	function TransferButton:Update()
		self:SetText(
			ROTGB_LocalizeString(
				"rotgb_tg.buttons.transfer_cash",
				ROTGB_FormatCash(ROTGB_GetTransferAmount(LocalPlayer()))
			)
		) -- I feel like I've seen this many successive closing brackets before...
	end
	
	return TransferButton
end

local function CreateSilkiconScalerPanel(child, parent)
	local Panel = vgui.Create("DPanel", parent)
	Panel.Paint = nil
	child:SetParent(Panel)
	function Panel:PerformLayout(w,h)
		local childSize = math.floor(w/16)*16
		child:SetSize(childSize, childSize)
		child:Center()
	end
	
	return Panel
end

local function DrawVolumeBackground(panel, w, h)
	draw.RoundedBox(4, 0, 0, w, h, color_gray)
	draw.RoundedBox(4, 2, 2, w-4, h-4, color_black)
end

local function DrawVolumeSlider(panel, w, h)
	draw.RoundedBox(4, 0, 0, w, h, color_white)
	draw.RoundedBox(4, 2, 2, w-4, h-4, color_black)
end

local function CreateScoreboardVoiceCell(parent, ply)
	local baseWidth = FONT_SCOREBOARD_HEADER_HEIGHT*SCOREBOARD_CELL_WIDTH_MULTIPLIERS[1]
	local cellWidths = SCOREBOARD_CELL_WIDTH_MULTIPLIERS[7]
	local totalWidth = 0
	for k,v in pairs(cellWidths) do
		totalWidth = totalWidth + baseWidth * v
	end
	
	local VoiceCell = vgui.Create("DPanel", parent)
	local VoiceButton = vgui.Create("DImageButton")
	local VoiceButtonCell = CreateSilkiconScalerPanel(VoiceButton, VoiceCell)
	local VoiceSlider = vgui.Create("DSlider", VoiceCell)
	local VoiceTextEntry = vgui.Create("DTextEntry", VoiceCell)
	
	VoiceCell:SetWide(totalWidth)
	VoiceCell:Dock(RIGHT)
	VoiceCell:SetZPos(-7)
	VoiceCell.VolumeValue = -1
	function VoiceCell:UpdateVolume(newVolume, fromTextEntry)
		if newVolume ~= self.VolumeValue then
			self.VolumeValue = newVolume
			VoiceButton:UpdateImage(newVolume)
			VoiceSlider:SetSlideX(newVolume)
			if not fromTextEntry then
				VoiceTextEntry:SetText(math.Round(newVolume*100))
			end
			if IsValid(ply) then
				ply:SetVoiceVolumeScale(newVolume)
			end
		end
	end
	function VoiceCell:Update()
		if IsValid(ply) then
			VoiceTextEntry:SetTextColor(team.GetColor(ply:Team()))
			VoiceTextEntry:SetCursorColor(team.GetColor(ply:Team()))
		end
	end
	VoiceCell.Paint = nil
	
	function VoiceButton:DoClick()
		if VoiceCell.VolumeValue > 0 then
			VoiceCell.OldVolume = VoiceCell.VolumeValue
			VoiceCell:UpdateVolume(0)
		else
			VoiceCell:UpdateVolume(VoiceCell.OldVolume or 0.01)
		end
	end
	function VoiceButton:UpdateImage(newVolume)
		if newVolume <= 0 then
			self:SetImage("icon16/sound_none.png")
		elseif newVolume <= 0.5 then
			self:SetImage("icon16/sound_low.png")
		else
			self:SetImage("icon16/sound.png")
		end
	end
	
	VoiceButtonCell:SetWide(baseWidth*cellWidths[1])
	VoiceButtonCell:Dock(LEFT)
	
	VoiceSlider:SetWide(baseWidth*cellWidths[2])
	VoiceSlider:SetTrapInside(true) -- the GMod Wiki SAYS this doesn't do anything, but it actually does. "appears to be non-functioning" my ass
	VoiceSlider:Dock(FILL)
	VoiceSlider:SetLockY(0.5)
	VoiceSlider.Paint = DrawVolumeBackground
	VoiceSlider.Knob:SetSize(FONT_SCOREBOARD_HEADER_HEIGHT/2, FONT_SCOREBOARD_HEADER_HEIGHT)
	VoiceSlider.Knob.Paint = DrawVolumeSlider
	function VoiceSlider:TranslateValues(x, y)
		VoiceCell:UpdateVolume(x)
		return x, y
	end
	
	VoiceTextEntry:SetFont("rotgb_scoreboard_header")
	VoiceTextEntry:SetWide(baseWidth*cellWidths[3])
	VoiceTextEntry:Dock(RIGHT)
	VoiceTextEntry:SetPaintBackground(false)
	VoiceTextEntry:SetNumeric(true)
	function VoiceTextEntry:OnChange()
		local num = tonumber(self:GetValue())
		if num then
			VoiceCell:UpdateVolume(math.Round(num/100, 2), true)
		end
	end
	
	-- this was the old method, ditched because DNumSlider is a mess
	--[[local NumSlider = vgui.Create("DNumSlider", parent)
	NumSlider:SetWide(FONT_SCOREBOARD_HEADER_HEIGHT*SCOREBOARD_CELL_WIDTH_MULTIPLIERS[6])
	NumSlider:Dock(RIGHT)
	NumSlider:SetZPos(6)
	NumSlider:SetDecimals(2)
	NumSlider:SetMinMax(0, 100)
	NumSlider:SetDefaultValue(100)
	function NumSlider:OnValueChanged(value)
		ply:SetMuted(value <= 0)
		ply:SetVoiceVolumeScale(value / 100)
	end]]
	
	VoiceCell:UpdateVolume(ply:GetVoiceVolumeScale())
	
	return VoiceCell
end

local function CreateScoreboardKickCell(parent, ply)
	local KickButton = CreateButton(parent, "#rotgb_tg.buttons.kick", color_red, function()
		hook.Run("ShowVoteMenu", {typ=RTG_VOTE_KICK, target=ply:UserID()})
	end)
	
	KickButton.Paint = ButtonPaintSmall
	KickButton:SetFont("rotgb_scoreboard_header")
	KickButton:SetWide(FONT_SCOREBOARD_BODY_HEIGHT*SCOREBOARD_CELL_WIDTH_MULTIPLIERS[1]*SCOREBOARD_CELL_WIDTH_MULTIPLIERS[8])
	KickButton:Dock(RIGHT)
	KickButton:SetZPos(-8)
	return KickButton
end

local function DrawScoreboardRow(panel, w, h)
	draw.RoundedBox(4, 0, 0, w, h, panel._Color or color_white)
	draw.RoundedBox(4, SCOREBOARD_PADDING, SCOREBOARD_PADDING, w-SCOREBOARD_PADDING*2, h-SCOREBOARD_PADDING*2, color_black)
end

local function CreateScoreboardHeader(parent, zPos)
	local Panel = vgui.Create("DPanel", parent)
	Panel:SetTall(FONT_SCOREBOARD_HEADER_HEIGHT+SCOREBOARD_PADDING*2)
	Panel:SetZPos(zPos)
	Panel:Dock(TOP)
	Panel:DockPadding(SCOREBOARD_PADDING, SCOREBOARD_PADDING, SCOREBOARD_PADDING, SCOREBOARD_PADDING)
	Panel.Paint = nil
	--Panel._Color = teamColor
	
	-- attach the panels in reverse of the SCOREBOARD_FIELDS table
	for i=8,1,-1 do
		local width = SCOREBOARD_CELL_WIDTH_MULTIPLIERS[i]
		if istable(width) then
			local innerwidth = 0
			for k,v in pairs(width) do
				innerwidth = innerwidth + v
			end
			width = innerwidth
		end
		width = width * FONT_SCOREBOARD_BODY_HEIGHT*SCOREBOARD_CELL_WIDTH_MULTIPLIERS[1]
		
		local textCell = vgui.Create("DLabel", Panel)
		textCell:SetText(SCOREBOARD_FIELDS[i])
		textCell:SetFont("rotgb_scoreboard_header")
		textCell:SetTextColor(color_white)
		textCell:SetZPos(-i)
		if i==1 then
			textCell:Dock(FILL)
		else
			textCell:DockMargin(FONT_SCOREBOARD_BODY_HEIGHT*SCOREBOARD_CELL_SPACE,0,0,0)
			textCell:SetWide(width)
			textCell:Dock(RIGHT)
		end
	end
	
	return Panel
end

local function CreateScoreboardRow(parent, ply, zPos)
	local teamColor = team.GetColor(ply:Team())
	local Panel = vgui.Create("DPanel", parent)
	Panel:SetTall(FONT_SCOREBOARD_HEADER_HEIGHT+SCOREBOARD_PADDING*2)
	Panel:SetZPos(zPos)
	Panel:Dock(TOP)
	Panel:DockPadding(SCOREBOARD_PADDING, SCOREBOARD_PADDING, SCOREBOARD_PADDING, SCOREBOARD_PADDING)
	Panel.Paint = DrawScoreboardRow
	Panel.Cells = {}
	--Panel._Color = teamColor
	
	-- attach the panels in reverse of the SCOREBOARD_FIELDS table
	for i=8,1,-1 do
		local cell
		if SCOREBOARD_FUNCS[i] then
			cell = vgui.Create("DLabel", Panel)
			cell:SetWide(FONT_SCOREBOARD_BODY_HEIGHT*SCOREBOARD_CELL_WIDTH_MULTIPLIERS[1]*SCOREBOARD_CELL_WIDTH_MULTIPLIERS[i])
			cell:SetFont("rotgb_scoreboard_body")
			cell:SetTextColor(teamColor)
			cell:SetZPos(-i)
			cell:Dock(RIGHT)
			function cell:Update()
				cell:SetText(SCOREBOARD_FUNCS[i](ply))
			end
		elseif i == 1 then
			cell = CreateScoreboardNameCell(Panel, ply)
		elseif i == 5 then
			cell = CreateScoreboardOtherLevelCell(Panel, ply)
		elseif i == 6 then
			cell = CreateScoreboardTransferCell(Panel, ply)
		elseif i == 7 then
			cell = CreateScoreboardVoiceCell(Panel, ply)
		elseif i == 8 then
			cell = CreateScoreboardKickCell(Panel, ply)
		end
		if i ~= 1 then
			cell:DockMargin(FONT_SCOREBOARD_BODY_HEIGHT*SCOREBOARD_CELL_SPACE,0,0,0)
		end
		Panel.Cells[i] = cell
	end
	
	function Panel:Update()
		if IsValid(ply) then
			self._Color = team.GetColor(ply:Team())
			
			for k,v in pairs(self.Cells) do
				if v.Update then
					v:Update()
				end
			end
		elseif IsValid(parent) then
			parent:MarkScoreboardForRecreation()
		end
	end
	
	return Panel
end

local function CreateScoreboardPanel(parent)
	local Panel = vgui.Create("DScrollPanel", parent)
	Panel:Dock(FILL)
	Panel.PlayerCount = player.GetCount()
	Panel.Scores = {}
	Panel.PlayerOrder = {}
	Panel.ScoreboardRows = {}
	Panel.PlayerTeams = {}
	Panel.ScoreboardNeedsRefresh = false
	-- I have NO idea if the Think function is being used by anything
	-- but better to be safe than sorry
	Panel.OldThink = Panel.Think
	Panel.NextUpdate = 0
	function Panel:Think()
		if self.NextUpdate < RealTime() then
			self.NextUpdate = RealTime() + GAMEMODE.NetSendInterval
			if self.PlayerCount ~= player.GetCount() then
				self.PlayerCount = player.GetCount()
				self:MarkScoreboardForRecreation()
			end
			if self.ScoreboardNeedsRefresh then
				self:RecreateScoreboard()
				self.ScoreboardNeedsRefresh = false
			end
			for k,v in pairs(self.ScoreboardRows) do
				if v.Update then
					v:Update()
				end
			end
		end
		if self.OldThink then
			self:OldThink()
		end
	end
	function Panel:ScoreUpdate(ply, score)
		self.Scores[ply] = score
		local i = 1
		for k,v in SortedPairsByValue(self.Scores, true) do
			if self.PlayerOrder[i] ~= k then
				self:MarkScoreboardForRecreation()
				break
			end
			i = i + 1
		end
	end
	function Panel:MarkScoreboardForRecreation()
		self.ScoreboardNeedsRefresh = true
	end
	function Panel:RecreateScoreboard()
		for k,v in pairs(self.ScoreboardRows) do
			v:Remove()
		end
		table.Empty(self.ScoreboardRows)
		
		self.ScoreboardRows[1] = CreateScoreboardHeader(self, 0)
		table.Empty(self.PlayerOrder)
		for k,v in SortedPairsByValue(self.Scores, true) do
			table.insert(self.PlayerOrder, k)
		end
		for k,v in pairs(self.PlayerOrder) do
			self.ScoreboardRows[k+1] = CreateScoreboardRow(self, v, k)
		end
	end
	
	for k,v in pairs(player.GetAll()) do
		Panel:ScoreUpdate(v, v.rtg_gBalloonPops or 0)
	end
	Panel:Think()
	return Panel
end

--[=[local function CreateMVPPanel(parent, zPos)
	local plys = player.GetAll()
	table.sort(plys, function(ply1, ply2)
		return (ply1.rtg_gBalloonPops or 0) > (ply2.rtg_gBalloonPops or 0)
	end)
	local panelHeight = FONT_HEADER_HEIGHT+FONT_BODY_HEIGHT*2*#plys
	
	--[[local Panel = vgui.Create("DPanel", parent)
	Panel:SetTall(panelHeight)
	Panel:Dock(TOP)
	Panel:SetZPos(zPos)
	
	CreateHeader(Panel, 1, "Most Valued Players:")
	
	for i,v in ipairs(plys) do
		local PlayerPanel = vgui.Create("DPanel", parent)
		PlayerPanel:SetTall(FONT_BODY_HEIGHT*2)
		PlayerPanel:Dock(TOP)
		PlayerPanel:SetZPos(i+1)
		PlayerPanel.Paint = ScoreboardRowPaint
		PlayerPanel._Team = v:Team()
	end]]
	
	local Panel = vgui.Create("DListView", parent)
	Panel:SetTall(panelHeight)
	Panel:Dock(TOP)
	Panel:SetZPos(zPos)
	Panel:SetSortable(false)
	Panel:SetHeaderHeight(FONT_HEADER_HEIGHT)
	Panel:SetDataHeight(FONT_BODY_HEIGHT)
	Panel.Paint = nil
	
	local Column1 = Panel:AddColumn("Most Valued Players", 1)
	Column1.Header:SetTextColor(color_white)
	Column1.Header:SetFont("rotgb_header")
	Column1.Header.Paint = nil
	local Column2 = Panel:AddColumn("Damage", 2)
	Column2.Header:SetTextColor(color_white)
	Column2.Header:SetFont("rotgb_header")
	Column2.Header.Paint = nil
	
	for i,v in ipairs(plys) do
		local PlayerRow = Panel:AddLine(v:Nick(), v.rtg_gBalloonPops or 0)
		PlayerRow:SetFontInternal("rotgb_body")
		PlayerRow.Paint = ScoreboardRowPaint
		PlayerRow._Color = team.GetColor(v:Team())
	end
	
	return Panel
end]=]

local function ExitButtonFunction()
	Derma_Query("#rotgb_tg.buttons.disconnect.warning", "#quit", "#GameUI_Yes", function()
		RunConsoleCommand("disconnect")
	end, "#GameUI_No")
end

local function CreateGameOverButtons(parent, canContinue)
	local ExitButton = CreateButton(nil, "#rotgb_tg.buttons.disconnect", color_red, ExitButtonFunction)
	local ExitButtonCenteringPanel = CreateElementCenteringPanel(ExitButton, parent)
	ExitButtonCenteringPanel:SetZPos(1)
	ExitButtonCenteringPanel:Dock(BOTTOM)
	
	local RestartButton = CreateButton(nil, "#rotgb_tg.buttons.restart", color_yellow, function()
		Derma_Query("#rotgb_tg.buttons.restart.warning", "#new_game", "#GameUI_Yes", function()
			net.Start("rotgb_gamemode")
			net.WriteUInt(RTG_OPERATION_GAMEOVER, 4)
			net.SendToServer()
			parent:Close()
		end, "#GameUI_No")
	end)
	local RestartButtonCenteringPanel = CreateElementCenteringPanel(RestartButton, parent)
	RestartButtonCenteringPanel:SetZPos(2)
	RestartButtonCenteringPanel:Dock(BOTTOM)
	
	local VoteButton = CreateButton(nil, "#rotgb_tg.buttons.start_vote", color_green, function()
		parent:Close()
		RunConsoleCommand("rotgb_tg_vote")
	end)
	local VoteButtonCenteringPanel = CreateElementCenteringPanel(VoteButton, parent)
	VoteButtonCenteringPanel:SetZPos(3)
	VoteButtonCenteringPanel:Dock(BOTTOM)
	
	if canContinue then
		local ContinueButton = CreateButton(nil, "#rotgb_tg.buttons.freeplay", color_aqua, function()
			parent:Close()
		end)
		local ContinueButtonCenteringPanel = CreateElementCenteringPanel(ContinueButton, parent)
		ContinueButtonCenteringPanel:SetZPos(4)
		ContinueButtonCenteringPanel:Dock(BOTTOM)
	end
end

local function CreateDifficultyDescriptionPanel()
	local Panel = vgui.Create("DPanel")
	Panel.Paint = nil
	
	local Header = CreateHeader(Panel, 1, "#rotgb_tg.difficulty.info.header")
	local Text = CreateText(Panel, 2, "")
	
	function Panel:DifficultySelected(difficulty)
		if difficulty then
			Header:SetText(ROTGB_LocalizeString(
				"rotgb_tg.difficulty.subcategory",
				language.GetPhrase("rotgb_tg.difficulty.category."..GAMEMODE.Modes[difficulty].category),
				language.GetPhrase("rotgb_tg.difficulty."..difficulty..".name")
			))
			Text:SetText("#rotgb_tg.difficulty."..difficulty..".description")
		else
			Header:SetText("#rotgb_tg.difficulty.info.header")
			Text:SetText("")
		end
	end
	
	return Panel
end

local function DrawTreeNode(panel, w, h)
	-- Garry's method doesn't account for panel:GetLineHeight()
	-- which is why it needs to be overwritten
	if not panel.m_bDrawLines then return end
	local halfLineHeight = panel:GetLineHeight()/2
	surface.SetDrawColor(255, 255, 255)
	
	if panel.m_bLastChild then
		surface.DrawRect(halfLineHeight, 0, 1, halfLineHeight)
		surface.DrawRect(halfLineHeight, halfLineHeight, halfLineHeight, 1)
	else
		surface.DrawRect(halfLineHeight, 0, 1, halfLineHeight*2)
		surface.DrawRect(halfLineHeight, halfLineHeight, halfLineHeight, 1)
	end
end

local function LayoutTreeNode(panel)
	if panel:IsRootNode() then
		return panel:PerformRootNodeLayout()
	end
	if panel.animSlide:Active() then return end
	
	local LineHeight = panel:GetLineHeight()
	if panel.m_bHideExpander then
		panel.Expander:SetPos(-LineHeight, 0)
		panel.Expander:SetSize(LineHeight, LineHeight)
		panel.Expander:SetVisible(false)
	else
		panel.Expander:SetPos(0, 0)
		panel.Expander:SetSize(LineHeight, LineHeight)
		panel.Expander:SetVisible(panel:HasChildren() or panel:GetForceShowExpander())
		panel.Expander:SetZPos(10)
	end
	
	panel.Label:StretchToParent(0, nil, 0, nil)
	panel.Label:SetTall(LineHeight)
	if panel:ShowIcons() then
		panel.Icon:SetVisible(true)
		panel.Icon:SetPos(panel.Expander.x + panel.Expander:GetWide() + 4, (LineHeight - panel.Icon:GetTall())/2)
		panel.Label:SetTextInset(panel.Icon.x + panel.Icon:GetWide() + 4, 0)
	else
		panel.Icon:SetVisible(false)
		panel.Label:SetTextInset(panel.Expander.x + panel.Expander:GetWide() + 4, 0)
	end
	
	if not IsValid(panel.ChildNodes) or not panel.ChildNodes:IsVisible() then
		panel:SetTall(LineHeight)
		return
	end
	
	panel.ChildNodes:SizeToContents()
	panel:SetTall(LineHeight + panel.ChildNodes:GetTall())
	panel.ChildNodes:StretchToParent(LineHeight, LineHeight, 0, 0)
	panel:DoChildrenOrder()
end

--[[local function DrawExpanderButton(panel, w, h)
	
end]]

local function DrawNodeLabel(panel, w, h)
	if not panel.m_bSelected then return end
	local parent = panel:GetParent()
	local color = Color(255, 255, 255, TimedSin(1, 63, 127, 0))
	draw.RoundedBox(4, parent:GetLineHeight(), 0, panel:GetTextSize()+panel:GetTextInset()-parent:GetLineHeight(), h, color)
end

local function CreateDifficultySelectionPanel(parent)
	local Divider = vgui.Create("DHorizontalDivider", parent)
	Divider:Dock(FILL)
	Divider:SetDividerWidth(FONT_BODY_HEIGHT)
	Divider:SetLeftWidth((parent:GetWide()-FONT_BODY_HEIGHT)/2-indentX)
	function Divider:DifficultySelectedInternal(difficulty)
		self:DifficultySelected(difficulty)
		Divider:GetRight():DifficultySelected(difficulty)
	end
	Divider:SetRight(CreateDifficultyDescriptionPanel())
	
	local DTree = vgui.Create("DTree", parent)
	Divider:SetLeft(DTree)
	DTree:SetLineHeight(FONT_BODY_HEIGHT)
	DTree.Paint = nil
	
	local completedDifficulties = hook.Run("GetCompletedDifficulties")[game.GetMap()] or {}
	
	for i,v in ipairs(hook.Run("GetGamemodeDifficultyNodes")) do
		local node = DTree:AddNode("#rotgb_tg.difficulty.category."..v.name, "icon16/bricks.png")
		node:SetExpanded(true, true)
		node.Label:SetFont("rotgb_body")
		node.Label:SetTextColor(color_white)
		node.Label.Paint = DrawNodeLabel
		node.Expander:SetSize(node:GetLineHeight(), node:GetLineHeight())
		--node.Expander.Paint = DrawExpanderButton
		node.Paint = DrawTreeNode
		node.PerformLayout = LayoutTreeNode
		function node:DoClick()
			Divider:DifficultySelectedInternal(nil)
		end
		
		local allCompleted = true
		
		for i2,v2 in ipairs(v.subnodes) do
			local completed = bit.band(completedDifficulties[v2.name] or 0, 1)==1
			allCompleted = allCompleted and completed
			
			local subnode = node:AddNode("#rotgb_tg.difficulty."..v2.name..".name", completed and "icon16/tick.png" or "icon16/brick.png")
			subnode.Label:SetFont("rotgb_body")
			subnode.Label:SetTextColor(completed and color_light_green or color_white)
			subnode.Label.Paint = DrawNodeLabel
			subnode.Expander:SetSize(subnode:GetLineHeight(), subnode:GetLineHeight())
			subnode.name = v2.name
			subnode.Paint = DrawTreeNode
			subnode.PerformLayout = LayoutTreeNode
			function subnode:DoClick()
				Divider:DifficultySelectedInternal(self.name)
			end
		end
		
		if allCompleted then
			node:SetIcon("icon16/tick.png")
			node.Label:SetTextColor(color_light_green)
		end
	end
	
	return Divider
end

local function CreateDifficultyConfirmButtonPanel(parent, DifficultySelectionPanel, zPos)
	local newDifficulty = nil
	local button = CreateButton(nil, "#rotgb_tg.buttons.select_difficulty", color_green, function()
		net.Start("rotgb_gamemode")
		net.WriteUInt(RTG_OPERATION_DIFFICULTY, 4)
		net.WriteString(newDifficulty)
		net.SendToServer()
		hook.Run("HideDifficultySelection")
	end)
	local Panel = CreateElementCenteringPanel(button, parent)
	
	Panel:SetZPos(zPos)
	Panel:Dock(BOTTOM)
	button:SetEnabled(false)
	
	function DifficultySelectionPanel:DifficultySelected(difficulty)
		if difficulty then
			newDifficulty = difficulty
			button:SetCursor("hand")
			button:SetEnabled(true)
		else
			button:SetCursor("no")
			button:SetEnabled(false)
		end
	end
	
	return Panel
end

local function CreateDifficultyCancelButtonPanel(parent, zPos)
	local button = CreateButton(Panel, "#rotgb_tg.buttons.cancel", color_red, function()
		hook.Run("HideDifficultySelection")
	end)
	local Panel = CreateElementCenteringPanel(button, parent)
	
	Panel:SetZPos(zPos)
	Panel:Dock(BOTTOM)
	
	return Panel
end

local function CreateVoteLeftPanel()
	local Panel = vgui.Create("DScrollPanel")
	
	local KickButton = CreateButton(Panel, "#rotgb_tg.voting.kick", color_red, function()
		Panel:UpdateRightPanel(RTG_VOTE_KICK)
	end)
	KickButton:DockMargin(0,0,0,FONT_HEADER_HEIGHT)
	KickButton:SetZPos(1)
	KickButton:Dock(TOP)
	
	local DifficultyButton = CreateButton(Panel, "#rotgb_tg.voting.change_difficulty", color_yellow, function()
		Panel:UpdateRightPanel(RTG_VOTE_CHANGEDIFFICULTY)
	end)
	DifficultyButton:DockMargin(0,0,0,FONT_HEADER_HEIGHT)
	DifficultyButton:SetZPos(2)
	DifficultyButton:Dock(TOP)
	
	local RestartButton = CreateButton(Panel, "#rotgb_tg.voting.restart", color_green, function()
		Panel:UpdateRightPanel(RTG_VOTE_RESTART)
	end)
	RestartButton:DockMargin(0,0,0,FONT_HEADER_HEIGHT)
	RestartButton:SetZPos(3)
	RestartButton:Dock(TOP)
	
	local MapButton = CreateButton(Panel, "#rotgb_tg.voting.change_map", color_aqua, function()
		Panel:UpdateRightPanel(RTG_VOTE_MAP)
	end)
	MapButton:DockMargin(0,0,0,FONT_HEADER_HEIGHT)
	MapButton:SetZPos(4)
	MapButton:Dock(TOP)
	
	return Panel
end

local function CreateVoteRightPanel(VoteLeftPanel, data)
	local Panel = vgui.Create("DScrollPanel")
	Panel.TargetButtons = {}
	
	function VoteLeftPanel:UpdateRightPanel(voteType)
		for k,v in pairs(Panel.TargetButtons) do
			v:Remove()
		end
		table.Empty(Panel.TargetButtons)
		if voteType == RTG_VOTE_KICK then
			local plys = player.GetAll()
			local nicknames = {}
			for k,v in pairs(plys) do
				table.insert(nicknames, v:Nick())
			end
			local nickFreq = table.GetValuesCount(nicknames)
			local playerTable = {}
			for k,v in pairs(plys) do
				table.insert(playerTable, {joinTime = v:GetCreationTime(), name = v:Nick(), duped = nickFreq[v:Nick()] > 1, userid = v:UserID(), team = v:Team()})
			end
			table.sort(playerTable, function(a,b)
				if a.name == b.name then return a.jointime < b.jointime
				else return a.name < b.name
				end
			end)
			-- so now we have a sorted player table, now actually make the buttons
			for i,v in ipairs(playerTable) do
				local plyString = v.duped and ROTGB_LocalizeString(
					"rotgb_tg.voting.kick.player_with_join_time",
					v.name,
					string.format("%i", CurTime()-v.joinTime)
				) or ROTGB_LocalizeString(
					"rotgb_tg.voting.kick.player",
					v.name
				)
				local button = CreateButton(Panel, plyString, team.GetColor(v.team), function(self)
					for k,v in pairs(Panel.TargetButtons) do
						v:SetFlashing(v == self)
					end
					Panel:SetVote(RTG_VOTE_KICK, self.VoteTarget)
				end)
				button.VoteTarget = v.userid
				button:SetZPos(i)
				button:DockMargin(0,0,0,FONT_HEADER_HEIGHT)
				button:Dock(TOP)
				table.insert(Panel.TargetButtons, button)
			end
		elseif voteType == RTG_VOTE_CHANGEDIFFICULTY then
			for i,v in ipairs(hook.Run("GetGamemodeDifficultyNodes")) do
				for j,v2 in ipairs(v.subnodes) do
					local difficultyString = ROTGB_LocalizeString(
						"rotgb_tg.difficulty.subcategory",
						language.GetPhrase("rotgb_tg.difficulty.category."..v.name),
						language.GetPhrase("rotgb_tg.difficulty."..v2.name..".name")
					)
					local button = CreateButton(Panel, difficultyString, CATEGORY_COLORS[i], function(self)
						for k,v3 in pairs(Panel.TargetButtons) do
							v3:SetFlashing(v3 == self)
						end
						Panel:SetVote(RTG_VOTE_CHANGEDIFFICULTY, self.VoteTarget)
					end)
					button.VoteTarget = v2.name
					button:SetZPos(i*10+j)
					button:DockMargin(0,0,0,FONT_HEADER_HEIGHT)
					button:Dock(TOP)
					table.insert(Panel.TargetButtons, button)
				end
			end
		elseif voteType == RTG_VOTE_RESTART then
			local QuickButton = CreateButton(Panel, "#rotgb_tg.voting.restart.quick", color_green, function(self)
				for k,v in pairs(Panel.TargetButtons) do
					v:SetFlashing(v == self)
				end
				Panel:SetVote(RTG_VOTE_RESTART, self.VoteTarget)
			end)
			QuickButton.VoteTarget = "1"
			QuickButton:SetZPos(1)
			QuickButton:DockMargin(0,0,0,FONT_HEADER_HEIGHT)
			QuickButton:Dock(TOP)
			table.insert(Panel.TargetButtons, QuickButton)
			
			local MapButton = CreateButton(Panel, "#rotgb_tg.voting.restart.full", color_yellow, function(self)
				for k,v in pairs(Panel.TargetButtons) do
					v:SetFlashing(v == self)
				end
				Panel:SetVote(RTG_VOTE_RESTART, self.VoteTarget)
			end)
			MapButton.VoteTarget = "2"
			MapButton:SetZPos(2)
			MapButton:DockMargin(0,0,0,FONT_HEADER_HEIGHT)
			MapButton:Dock(TOP)
			table.insert(Panel.TargetButtons, MapButton)
		elseif voteType == RTG_VOTE_MAP then
			if hook.Run("GetMapTable") then
				for k,v in pairs(hook.Run("GetMapTable")) do
					local button = CreateButton(Panel, v, color_green, function(self)
						for k2,v2 in pairs(Panel.TargetButtons) do
							v2:SetFlashing(v2 == self)
						end
						Panel:SetVote(RTG_VOTE_MAP, self.VoteTarget)
					end)
					button.VoteTarget = v
					button:SetZPos(k)
					button:DockMargin(0,0,0,FONT_HEADER_HEIGHT)
					button:Dock(TOP)
					table.insert(Panel.TargetButtons, button)
				end
			else -- request from server
				net.Start("rotgb_gamemode")
				net.WriteUInt(RTG_OPERATION_MAPS, 4)
				net.SendToServer()
			end
		end
	end
	
	function Panel:TriggerButtonByTarget(target)
		for k,v in pairs(Panel.TargetButtons) do
			if v.VoteTarget == target then
				v:DoClick() break
			end
		end
	end
	
	if data then
		VoteLeftPanel:UpdateRightPanel(data.typ)
	end
	
	return Panel
end

local function CreateVoteReasonPanel()
	local Panel = vgui.Create("DPanel")
	Panel.Paint = DrawTextBoxBackground
	
	local TextEntry = vgui.Create("DTextEntry", Panel)
	TextEntry:Dock(FILL)
	TextEntry:SetFont("rotgb_body")
	TextEntry:SetTall(FONT_BODY_HEIGHT*5)
	TextEntry:SetPlaceholderText("#rotgb_tg.voting.reason")
	TextEntry:SetPaintBackground(false)
	TextEntry:SetTextColor(color_white)
	
	function Panel:GetValue()
		return TextEntry:GetValue()
	end
	
	return Panel
end

local function CreateVoteButtonPanel(Menu, VoteRightPanel, VoteReasonPanel, data)
	local VoteButtonPanel = vgui.Create("DPanel")
	
	local StartVoteButton = CreateButton(VoteButtonPanel, "#rotgb_tg.buttons.start_vote", color_green, function()
		net.Start("rotgb_gamemode")
		net.WriteUInt(RTG_OPERATION_VOTESTART, 4)
		net.WriteUInt(VoteButtonPanel.VoteType, 4)
		net.WriteString(VoteButtonPanel.VoteTarget)
		net.WriteString(VoteReasonPanel:GetValue() or "")
		net.SendToServer()
		Menu:Close()
	end)
	local BackButton = CreateButton(VoteButtonPanel, "#rotgb_tg.buttons.cancel", color_yellow, function()
		Menu:Close()
	end)
	
	VoteButtonPanel:SetTall(StartVoteButton:GetTall()+BackButton:GetTall())
	VoteButtonPanel.Paint = nil
	StartVoteButton:SetEnabled(false)
	function VoteButtonPanel:PerformLayout(w, h)
		local svbW, svbH = StartVoteButton:GetSize()
		
		StartVoteButton:SetPos((w-svbW)/2, 0)
		BackButton:SetPos((w-BackButton:GetWide())/2, svbH)
	end
	function VoteRightPanel:SetVote(typ, target)
		VoteButtonPanel.VoteType = typ
		VoteButtonPanel.VoteTarget = target
		StartVoteButton:SetEnabled(true)
	end
	
	if data then
		VoteRightPanel:TriggerButtonByTarget(data.target)
	end
	
	return VoteButtonPanel
end

local function CreateVoterStatementPanel(parent, voteInfo)
	local RichText = vgui.Create("RichText", parent)
	RichText:SetVerticalScrollbarEnabled(false)
	RichText:SetFontInternal("rotgb_body")
	RichText:Dock(FILL)
	local initiatorColor = IsValid(voteInfo.initiator) and team.GetColor(voteInfo.initiator:Team()) or color_white
	local colorFragments = {initiatorColor}
	local replacementFragments = {IsValid(voteInfo.initiator) and voteInfo.initiator:Nick() or language.GetPhrase("rotgb_tg.voting.initiated.missing_player")}
	
	local voteType = voteInfo.typ
	if voteType == RTG_VOTE_KICK then
		local targetPlayer = Player(tonumber(voteInfo.target) or -1)
		if IsValid(targetPlayer) then
			table.insert(colorFragments, team.GetColor(targetPlayer:Team()))
			table.insert(replacementFragments, (ROTGB_LocalizeString("rotgb_tg.voting.initiated.kick", targetPlayer:Nick())))
		else
			table.insert(colorFragments, color_white)
			table.insert(replacementFragments, language.GetPhrase("rotgb_tg.voting.initiated.kick.missing_player"))
		end
	elseif voteType == RTG_VOTE_CHANGEDIFFICULTY then
		local targetDifficulty = voteInfo.target
		local targetMode = GAMEMODE.Modes[targetDifficulty] or {}
		local category = targetMode.category
		table.insert(colorFragments, category and CATEGORY_COLORS[GAMEMODE.ModeCategories[category]] or color_white)
		table.insert(replacementFragments, (ROTGB_LocalizeString(
			"rotgb_tg.voting.initiated.difficulty",
			ROTGB_LocalizeString(
				"rotgb_tg.difficulty.subcategory",
				language.GetPhrase(category and "rotgb_tg.difficulty.category."..category or "rotgb_tg.difficulty.subcategory.invalid.1"),
				language.GetPhrase(category and "rotgb_tg.difficulty."..targetDifficulty..".name" or "rotgb_tg.difficulty.subcategory.invalid.2")
			)
		)))
	elseif voteType == RTG_VOTE_RESTART then
		local target = voteInfo.target
		if target == "1" then
			table.insert(colorFragments, color_green)
			table.insert(replacementFragments, language.GetPhrase("rotgb_tg.voting.initiated.restart.quick"))
		elseif target == "2" then
			table.insert(colorFragments, color_yellow)
			table.insert(replacementFragments, language.GetPhrase("rotgb_tg.voting.initiated.restart.full"))
		else
			table.insert(colorFragments, color_white)
			table.insert(replacementFragments, language.GetPhrase("rotgb_tg.voting.initiated.restart.invalid"))
		end
	elseif voteType == RTG_VOTE_MAP then
		table.insert(colorFragments, color_green)
		table.insert(replacementFragments, (ROTGB_LocalizeString("rotgb_tg.voting.initiated.change_map", voteInfo.target)))
	end
	
	if voteInfo.reason=="" then
		table.insert(colorFragments, color_yellow)
		table.insert(replacementFragments, language.GetPhrase("rotgb_tg.voting.initiated.no_reason"))
	else
		table.insert(colorFragments, color_yellow)
		table.insert(replacementFragments, (ROTGB_LocalizeString("rotgb_tg.voting.initiated.reason", voteInfo.reason)))
	end
	table.insert(colorFragments, color_green)
	table.insert(replacementFragments, language.GetPhrase("rotgb_tg.voting.initiated.hint.yes"))
	table.insert(colorFragments, color_red)
	table.insert(replacementFragments, language.GetPhrase("rotgb_tg.voting.initiated.hint.no"))
	
	hook.Run("InsertRichTextWithMulticoloredString", RichText, ROTGB_LocalizeMulticoloredString(
		"rotgb_tg.voting.initiated",
		replacementFragments,
		color_white,
		colorFragments
	))
	return RichText
end

local function CreateVoterTimerPanel(parent, zPos, voteInfo)
	local barHeight = FONT_BODY_HEIGHT/4
	
	local TimerPanel = vgui.Create("DPanel", parent)
	TimerPanel:SetTall(barHeight+FONT_BODY_HEIGHT)
	TimerPanel:SetZPos(zPos)
	TimerPanel:Dock(BOTTOM)
	
	local TextPanel = vgui.Create("DLabel", TimerPanel)
	TextPanel:SetTall(FONT_BODY_HEIGHT)
	TextPanel:SetFont("rotgb_body")
	TextPanel:SetTextColor(color_green)
	TextPanel:Dock(TOP)
	
	local ProgressPanel = vgui.Create("DProgress", TimerPanel)
	ProgressPanel:Dock(FILL)
	
	function TimerPanel:Paint(w, h)
		local timeLeft = voteInfo.expiry-RealTime()
		local timeLeftFraction = math.Remap(RealTime(), voteInfo.startTime, voteInfo.expiry, 1, 0)
		
		TextPanel:SetText(ROTGB_LocalizeString(
			"rotgb_tg.voting.initiated.time_left",
			string.format("%.1f", math.max(timeLeft, 0))
		))
		ProgressPanel:SetFraction(timeLeftFraction)
	end
	
	return TimerPanel
end

local function CreateVoterIndicatorsPanel(parent, zPos, voteInfo)
	local Panel = vgui.Create("DPanel", parent)
	local AgreePanel = vgui.Create("DPanel", Panel)
	local AgreeImage = vgui.Create("DImage")
	local AgreeImageScaler = CreateSilkiconScalerPanel(AgreeImage, AgreePanel)
	local AgreeCount = vgui.Create("DLabel", AgreePanel)
	local DisagreePanel = vgui.Create("DPanel", Panel)
	local DisagreeImage = vgui.Create("DImage")
	local DisagreeImageScaler = CreateSilkiconScalerPanel(DisagreeImage, DisagreePanel)
	local DisagreeCount = vgui.Create("DLabel", DisagreePanel)
	
	Panel:SetTall(FONT_BODY_HEIGHT)
	Panel:SetZPos(zPos)
	Panel:Dock(BOTTOM)
	Panel.Paint = nil
	Panel.VoteYes = 0
	Panel.VoteNo = 0
	function Panel:PerformLayout(w,h)
		AgreePanel:SetWide(w/2)
		DisagreePanel:SetWide(w/2)
	end
	function Panel:SetValues(yesAmount, noAmount)
		if yesAmount ~= self.VoteYes then
			AgreePanel:SetValue(yesAmount, yesAmount-self.VoteYes)
			self.VoteYes = yesAmount
		end
		if noAmount ~= self.VoteNo then
			DisagreePanel:SetValue(noAmount, noAmount-self.VoteNo)
			self.VoteNo = noAmount
		end
	end
	
	AgreePanel:Dock(LEFT)
	AgreePanel.Paint = nil
	function AgreePanel:SetValue(votes, diff)
		AgreeCount:SetText(string.format("%i", votes))
	end
	
	AgreeImage:SetImage("icon16/tick.png")
	
	AgreeImageScaler:SetWide(FONT_BODY_HEIGHT)
	AgreeImageScaler:Dock(LEFT)
	
	AgreeCount:Dock(FILL)
	AgreeCount:SetFont("rotgb_body")
	AgreeCount:SetTextColor(color_green)
	AgreeCount:SetText("0")
	
	DisagreePanel:Dock(FILL)
	DisagreePanel.Paint = nil
	function DisagreePanel:SetValue(votes, diff)
		DisagreeCount:SetText(string.format("%i", votes))
	end
	
	DisagreeImage:SetImage("icon16/cross.png")
	
	DisagreeImageScaler:SetWide(FONT_BODY_HEIGHT)
	DisagreeImageScaler:Dock(LEFT)
	
	DisagreeCount:Dock(FILL)
	DisagreeCount:SetFont("rotgb_body")
	DisagreeCount:SetTextColor(color_red)
	DisagreeCount:SetText("0")
	
	return Panel
end

local function VoterCallback(num)
	if num == 1 then
		net.Start("rotgb_statchanged")
		net.WriteUInt(RTG_STAT_VOTES, 4)
		net.WriteBool(true)
		net.SendToServer()
	elseif num == 2 then
		net.Start("rotgb_statchanged")
		net.WriteUInt(RTG_STAT_VOTES, 4)
		net.WriteBool(false)
		net.SendToServer()
	end
end

local function CreateVoterResultStatementHeader(parent, voteInfo, result)
	local succeeded = result == RTG_VOTERESULT_AGREED or result == RTG_VOTERESULT_KICKBYCHANGEDNICK
	local Header = vgui.Create("DLabel", parent)
	Header:Dock(TOP)
	Header:SetFont("rotgb_body")
	Header:SetTextColor(succeeded and color_green or color_red)
	Header:SetText(succeeded and "#GameUI_vote_passed" or "#GameUI_vote_failed")
	Header:SetTall(FONT_BODY_HEIGHT)
end

local function CreateVoterResultStatementPanel(parent, voteInfo, result)
	local RichText = vgui.Create("RichText", parent)
	RichText:SetVerticalScrollbarEnabled(false)
	RichText:Dock(FILL)
	local multiColoredText = {color_white}
	if result == RTG_VOTERESULT_NOTARGET then
		table.insert(multiColoredText, language.GetPhrase("rotgb_tg.voting.result.no_target"))
	elseif result == RTG_VOTERESULT_COOLDOWN then
		table.insert(multiColoredText, language.GetPhrase("rotgb_tg.voting.result.another_vote"))
	elseif result == RTG_VOTERESULT_DISAGREED then
		table.insert(multiColoredText, language.GetPhrase("rotgb_tg.voting.result.reject"))
	elseif result == RTG_VOTERESULT_KICKBYCHANGEDNICK then
		table.insert(multiColoredText, language.GetPhrase("rotgb_tg.voting.result.target_changed_nick"))
	elseif result == RTG_VOTERESULT_AGREED then
		local typ = voteInfo.typ
		if typ == RTG_VOTE_KICK then
			local target = Player(voteInfo.target)
			local userName = IsValid(target) and target:Nick() or "<already kicked>"
			local appendColor = IsValid(target) and team.GetColor(target:Team()) or color_gray
			table.Add(multiColoredText, ROTGB_LocalizeMulticoloredString(
				"rotgb_tg.voting.result.kick",
				{userName},
				color_white,
				{appendColor}
			))
		elseif typ == RTG_VOTE_CHANGEDIFFICULTY then
			local difficulty = voteInfo.target
			local target = GAMEMODE.Modes[difficulty]
			local difficultyName = ROTGB_LocalizeString(
				"rotgb_tg.difficulty.subcategory",
				language.GetPhrase(target and "rotgb_tg.difficulty.category."..target.category or "rotgb_tg.difficulty.subcategory.invalid.1"),
				language.GetPhrase(target and "rotgb_tg.difficulty."..difficulty..".name" or "rotgb_tg.difficulty.subcategory.invalid.2")
			)
			local appendColor = CATEGORY_COLORS[GAMEMODE.ModeCategories[target.category]]
			table.Add(multiColoredText, ROTGB_LocalizeMulticoloredString(
				"rotgb_tg.voting.result.difficulty",
				{difficultyName},
				color_white,
				{appendColor}
			))
		elseif typ == RTG_VOTE_RESTART then
			table.insert(multiColoredText, language.GetPhrase("rotgb_tg.voting.result.restart"))
		elseif typ == RTG_VOTE_MAP then
			table.Add(multiColoredText, ROTGB_LocalizeMulticoloredString(
				"rotgb_tg.voting.result.map",
				{voteInfo.target},
				color_white,
				{color_green}
			))
		end
	end
	hook.Run("InsertRichTextWithMulticoloredString", RichText, multiColoredText)
	return RichText
end

local function CreateSkillButton(parent, skillID, skillTier)
	-- we're not using a DButton here since it's a lot less efficient,
	-- we want to have MANY of these buttons at the same time after all!
	local button = vgui.Create("DPanel", parent)
	button:SetCursor("hand")
	--button:NoClipping(true)
	button:SetPaintedManually(true)
	button.rtg_ActivateTime = -SKILL_ACTIVATE_TIME
	button.rtg_SinePhase = math.random()*math.pi*2
	
	local radiusMultiplier = SKILL_SPRITE_RADIUS_MULTIPLIERS[skillTier+1]
	
	function button:OnMousePressed(mousecode)
		if mousecode == MOUSE_LEFT then
			self:MouseCapture(true)
		end
	end
	function button:OnMouseReleased(mousecode)
		if mousecode == MOUSE_LEFT then
			if self:IsHovered() then
				self:UnlockPerk()
			end
			self:MouseCapture(false)
		end
	end
	function button:OnCursorEntered()
		parent:OnSkillHovered(skillID)
	end
	function button:OnCursorExited()
		parent:OnSkillUnhovered(skillID)
	end
	function button:TestHover(x,y)
		local halfWidth = self:GetWide()/2
		x,y = self:ScreenToLocal(x,y)
		return (x - halfWidth)^2 + (y - halfWidth)^2 <= (halfWidth*radiusMultiplier)^2
	end
	function button:Paint(w,h)
		local sineValue = math.sin(RealTime()*SKILL_SMOOTH_SPEED_MULTIPLIER+self.rtg_SinePhase)
		local size = math.Remap(sineValue, -1, 1, SKILL_SMOOTH_SIZE_MIN, SKILL_SMOOTH_SIZE_MAX)*self:GetWide()
		
		if self.rtg_ActivateTime then
			if self.rtg_ActivateTime < RealTime() then
				self.rtg_ActivateTime = nil
			else
				local t = (self.rtg_ActivateTime-RealTime())/SKILL_ACTIVATE_TIME
				size = size * Lerp(math.EaseInOut(t,1,0), 1, SKILL_ACTIVATE_SIZE)
			end
		end
		
		local offset = (self:GetWide() - size)/2
		surface.SetMaterial(parent:GetSkillMaterial(skillID))
		surface.SetDrawColor(255,255,255)
		surface.DrawTexturedRect(offset, offset, size, size)
	end
	
	function button:MoveToPositionAndSize(position, size)
		self:SetSize(size, size)
		self:SetPos(position:Unpack())
		self.rtg_VectorTablePos = position:Copy()
		self.rtg_VectorTablePos:AddDistributed(size/2)
	end
	function button:GetVectorTablePos()
		return self.rtg_VectorTablePos
	end
	function button:UnlockPerk()
		local ply = LocalPlayer()
		
		if ply:RTG_SkillUnlocked(skillID) and ply:RTG_GetSkillPoints()>0 then
			net.Start("rotgb_gamemode")
			net.WriteUInt(RTG_OPERATION_SKILLS, 4)
			net.WriteUInt(RTG_SKILL_ONE, 2)
			net.WriteUInt(skillID-1, 12)
			net.SendToServer()
		end
	end
	function button:ActivatePerk()
		self.rtg_ActivateTime = RealTime() + SKILL_ACTIVATE_TIME
	end
	
	return button
end

local function CreateTraitDescription(trait, amount)
	if trait=="skillEffectiveness" then
		return ROTGB_LocalizeMulticoloredString(
			"rotgb_tg.skills.traits.skillEffectiveness",
			{language.GetPhrase("rotgb_tg.skills.traits.skillEffectiveness.1"), string.format("%+.2f", amount)},
			color_white,
			{color_yellow, color_white}
		)
	else
		return ROTGB_LocalizeMulticoloredString(
			"rotgb_tg.skills.traits."..trait,
			{string.format("%+.2f", amount)},
			color_white,
			{color_yellow}
		)
	end
end

local function CreateSkillTooltip(skillTreeSurface)
	local tooltip = vgui.Create("DPanel", skillTreeSurface)
	tooltip:SetSize(32,32)
	tooltip.Paint = DrawTextBoxBackground
	function tooltip:Update(skills, skillID)
		local skill = skills[skillID]
		self.rtg_SkillTier = skill.tier
		local tierPalette = SKILL_TOOLTIP_TIERS[self.rtg_SkillTier+1]
		local maxWidth = 0
		
		self.rtg_TitleText:SetText("#rotgb_tg.skills.names."..skill.name)
		self.rtg_TitleText:SetTextColor(tierPalette[2])
		self.rtg_TitleText:SizeToContentsX()
		maxWidth = self.rtg_TitleText:GetWide()
		--[[self.rtg_TierText:SetText(tierPalette[1])
		self.rtg_TierText:SetTextColor(color_white)
		self.rtg_TierText:SizeToContentsX()
		maxWidth = math.max(maxWidth, self.rtg_TierText:GetWide())]]
		
		for k,v in pairs(self.rtg_DescTexts) do
			v:Remove()
		end
		table.Empty(self.rtg_DescTexts)
		
		local traits = istable(skill.trait) and table.Copy(skill.trait) or {skill.trait}
		local amounts = istable(skill.amount) and table.Copy(skill.amount) or {skill.amount}
		local skillEffectivenessMul = 1+hook.Run("GetSkillAmount", "skillEffectiveness")/100
		local targetHealthEffectivenessMul = 1+hook.Run("GetSkillAmount", "targetHealthEffectiveness")/100
		local skillExperienceEffectiveness = 1+hook.Run("GetSkillAmount", "skillExperienceEffectiveness")/100
		local skillExperiencePerWaveEffectiveness = 1+hook.Run("GetSkillAmount", "skillExperiencePerWaveEffectiveness")/100
		for k,v in pairs(amounts) do
			local trait = traits[k]
			if trait == "skillEffectiveness" then
				amounts[k] = v
			elseif trait == "targetHealth" then
				amounts[k] = v * skillEffectivenessMul * targetHealthEffectivenessMul
			elseif trait == "skillExperience" then
				amounts[k] = v * skillEffectivenessMul * skillExperienceEffectiveness
			elseif trait == "skillExperiencePerWave" then
				amounts[k] = v * skillEffectivenessMul * skillExperiencePerWaveEffectiveness
			else
				amounts[k] = v * skillEffectivenessMul
			end
		end
		surface.SetFont("rotgb_skill_body")
		for k,v in pairs(traits) do
			local textPanel = vgui.Create("DPanel", self)
			textPanel:SetPos(SKILL_TOOLTIP_PADDING, SKILL_TOOLTIP_PADDING+FONT_SKILL_BODY_HEIGHT*k)
			textPanel.rtg_Texts = CreateTraitDescription(v, amounts[k])
			
			-- the commented code below is no longer needed
			--[[-- if "{1}" eventually does get added, this part needs to be improved
			local traitText = traitsText[v]
			if traitText then 
				local pos2,pos3 = string.find(traitText, "{0}")
				local borders = {1,pos2,pos3 and pos3+1}
				
				for k2,v2 in pairs(borders) do
					local nextBorder = borders[k2+1]
					local subtext = string.sub(traitText, v2, (nextBorder or 0)-1)
					
					if k2%2==0 then
						textPanel.rtg_Texts[k2] = string.format("%+.2f", textPanel.amounts[k2/2])
					else
						textPanel.rtg_Texts[k2] = subtext
					end
				end
			else
				textPanel.rtg_Texts[1] = "No trait description found! Trait: "..v
			end]]
			
			function textPanel:Paint(w,h)
				draw.MultiColoredText(self.rtg_Texts, "rotgb_skill_body", 0, 0, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end
			
			self.rtg_DescTexts[k] = textPanel
			textPanel:SetSize(draw.GetMultiColoredTextSize(textPanel.rtg_Texts, "rotgb_skill_body"))
			maxWidth = math.max(maxWidth, textPanel:GetWide())
		end
		self:SetSize(maxWidth+SKILL_TOOLTIP_PADDING*2, FONT_SKILL_BODY_HEIGHT*(1+#traits)+SKILL_TOOLTIP_PADDING*2)
	end
	function tooltip:UpdateInfo()
		local maxWidth = 0
		
		self.rtg_TitleText:SetText("Current Skill Effects:")
		self.rtg_TitleText:SetTextColor(color_yellow)
		self.rtg_TitleText:SizeToContentsX()
		maxWidth = self.rtg_TitleText:GetWide()
		
		for k,v in pairs(self.rtg_DescTexts) do
			v:Remove()
		end
		table.Empty(self.rtg_DescTexts)
		
		-- FIXME: Is there a better way to invoke hook.Run("CreateSkillAmountsCache")?
		local skillEffectivenessMul = 1+hook.Run("GetSkillAmount", "skillEffectiveness")/100
		local traitsAndAmounts = hook.Run("GetCachedSkillAmounts")
		
		surface.SetFont("rotgb_skill_body")
		local order = 1
		for k,v in SortedPairs(traitsAndAmounts) do
			local textPanel = vgui.Create("DPanel", self)
			textPanel:SetPos(SKILL_TOOLTIP_PADDING, SKILL_TOOLTIP_PADDING+FONT_SKILL_BODY_HEIGHT*order)
			textPanel.rtg_Texts = CreateTraitDescription(k, v)
			
			function textPanel:Paint(w,h)
				draw.MultiColoredText(self.rtg_Texts, "rotgb_skill_body", 0, 0, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end
			self.rtg_DescTexts[order] = textPanel
			textPanel:SetSize(draw.GetMultiColoredTextSize(textPanel.rtg_Texts, "rotgb_skill_body"))
			
			maxWidth = math.max(maxWidth, textPanel:GetWide())
			order = order + 1
		end
		self:SetSize(maxWidth+SKILL_TOOLTIP_PADDING*2, FONT_SKILL_BODY_HEIGHT*order+SKILL_TOOLTIP_PADDING*2)
	end
	
	local titleText = vgui.Create("DLabel", tooltip)
	titleText:SetFont("rotgb_skill_body")
	titleText:SetTall(FONT_SKILL_BODY_HEIGHT)
	titleText:SetPos(SKILL_TOOLTIP_PADDING, SKILL_TOOLTIP_PADDING)
	tooltip.rtg_TitleText = titleText
	
	--[[local tierText = vgui.Create("DLabel", tooltip)
	tierText:SetFont("rotgb_skill_body")
	tierText:SetTall(FONT_SKILL_BODY_HEIGHT)
	tierText:SetPos(SKILL_TOOLTIP_PADDING, SKILL_TOOLTIP_PADDING+FONT_SKILL_BODY_HEIGHT)
	tooltip.rtg_TierText = tierText]]
	
	tooltip.rtg_DescTexts = {}
	
	return tooltip
end

local function CreateSkillSummaryPanel(parent)
	local tooltip = vgui.Create("DScrollPanel", parent)
	tooltip:Dock(FILL)
	tooltip:GetCanvas().Paint = DrawTextBoxBackground
	
	local titleText = vgui.Create("DLabel", tooltip)
	titleText:SetFont("rotgb_skill_body")
	titleText:SetTall(FONT_SKILL_BODY_HEIGHT)
	titleText:SetText("#rotgb_tg.skills.skill_effects")
	titleText:SetTextColor(color_light_orange)
	titleText:SizeToContentsX()
	titleText:Dock(TOP)
	
	-- FIXME: Is there a better way to invoke hook.Run("CreateSkillAmountsCache")?
	local skillEffectivenessMul = 1+hook.Run("GetSkillAmount", "skillEffectiveness")/100
	local traitsAndAmounts = hook.Run("GetCachedSkillAmounts")
	
	surface.SetFont("rotgb_skill_body")
	for k,v in SortedPairs(traitsAndAmounts) do
		if (tonumber(v) or 1) ~= 0 then
			local textPanel = vgui.Create("DPanel", tooltip)
			textPanel:SetTall(FONT_SKILL_BODY_HEIGHT)
			textPanel:Dock(TOP)
			textPanel.rtg_Texts = CreateTraitDescription(k, v)
			
			function textPanel:Paint(w,h)
				draw.MultiColoredText(self.rtg_Texts, "rotgb_skill_body", 0, 0, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end
		end
	end
	
	return tooltip
end

local function CreateSkillSummaryBackButton(parent)
	local backButton = CreateButton(nil, "#rotgb_tg.buttons.back", color_yellow, function(button)
		parent:CreateSkillWebSurface()
	end)
	local backButtonCenteringPanel = CreateElementCenteringPanel(backButton, parent)
	backButtonCenteringPanel:Dock(BOTTOM)
	
	return backButtonCenteringPanel
end

local function CreateSkillWebSurface(parent)
	local SKILL_RIGHT_TEXTS = {
		ROTGB_LocalizeMulticoloredString(
			"rotgb_tg.skills.hint.drag",
			{"#rotgb_tg.skills.hint.drag.1", "#rotgb_tg.skills.hint.drag.2"},
			color_white,
			{color_yellow, color_yellow}
		),
		ROTGB_LocalizeMulticoloredString(
			"rotgb_tg.skills.hint.keyboard",
			{"#rotgb_tg.skills.hint.keyboard.1", "#rotgb_tg.skills.hint.keyboard.2"},
			color_white,
			{color_yellow, color_yellow}
		),
		ROTGB_LocalizeMulticoloredString(
			"rotgb_tg.skills.hint.keyboard.reset",
			{"#rotgb_tg.skills.hint.keyboard.reset.1"},
			color_white,
			{color_yellow}
		)
	}

	local skills = hook.Run("GetSkills")
	local Surface = vgui.Create("DPanel", parent)
	local hoveredSkillID = 1
	local ply = LocalPlayer()
	Surface:Dock(FILL)
	Surface:SetMouseInputEnabled(true)
	Surface:SetKeyboardInputEnabled(true)
	Surface:SetCursor("sizeall")
	Surface.rtg_Radians = 0
	Surface.rtg_Offset = VectorTable(0,0)
	Surface.rtg_CenterOffset = VectorTable(0,0)
	Surface.rtg_LnScale = 0
	Surface.rtg_SkillPositionData = {}
	Surface.rtg_SkillButtons = {}
	Surface.rtg_KeyFlags = 0
	
	--[[function Surface:OnCursorEntered()
	end
	function Surface:OnCursorExited()
	end]]
	
	for k,v in pairs(skills) do
		local skillButton = CreateSkillButton(Surface, k, v.tier)
		skillButton.rtg_BeamPhase = math.random()*math.pi*2
		Surface.rtg_SkillButtons[k] = skillButton
	end
	
	function Surface:OnMousePressed(mousecode)
		if mousecode == MOUSE_LEFT then
			self.rtg_DragPos = VectorTable(self:CursorPos())
		elseif mousecode == MOUSE_RIGHT then
			self:SetCursor("sizewe")
			self.rtg_ZoomPos = VectorTable(self:CursorPos())
		end
		if not self.preventCapture then
			self:MouseCapture(true)
		end
	end
	function Surface:OnMouseReleased(mousecode)
		if mousecode == MOUSE_LEFT then
			self.rtg_DragPos = nil
		elseif mousecode == MOUSE_RIGHT then
			self:SetCursor("sizeall")
			self.rtg_ZoomPos = nil
		end
		if not (self.rtg_DragPos or self.rtg_ZoomPos or self.preventCapture) then
			self:MouseCapture(false)
		end
	end
	function Surface:OnMouseWheeled(downAmount)
		self:ZoomSkillWeb(0, -20*downAmount)
	end
	function Surface:OnCursorMoved(x,y)
	end
	function Surface:OnKeyCodePressed(key)
		if key == KEY_W then
			self.rtg_KeyFlags = bit.bor(self.rtg_KeyFlags, 1)
		elseif key == KEY_A then
			self.rtg_KeyFlags = bit.bor(self.rtg_KeyFlags, 2)
		elseif key == KEY_S then
			self.rtg_KeyFlags = bit.bor(self.rtg_KeyFlags, 4)
		elseif key == KEY_D then
			self.rtg_KeyFlags = bit.bor(self.rtg_KeyFlags, 8)
		elseif key == KEY_I then
			self.rtg_KeyFlags = bit.bor(self.rtg_KeyFlags, 16)
		elseif key == KEY_O then
			self.rtg_KeyFlags = bit.bor(self.rtg_KeyFlags, 32)
		elseif key == KEY_K then
			self.rtg_KeyFlags = bit.bor(self.rtg_KeyFlags, 64)
		elseif key == KEY_L then
			self.rtg_KeyFlags = bit.bor(self.rtg_KeyFlags, 128)
		elseif key == KEY_SPACE then
			self:ResetSkillWebCamera()
		end
	end
	function Surface:OnKeyCodeReleased(key)
		if key == KEY_W then
			self.rtg_KeyFlags = bit.band(self.rtg_KeyFlags, bit.bnot(1))
		elseif key == KEY_A then
			self.rtg_KeyFlags = bit.band(self.rtg_KeyFlags, bit.bnot(2))
		elseif key == KEY_S then
			self.rtg_KeyFlags = bit.band(self.rtg_KeyFlags, bit.bnot(4))
		elseif key == KEY_D then
			self.rtg_KeyFlags = bit.band(self.rtg_KeyFlags, bit.bnot(8))
		elseif key == KEY_I then
			self.rtg_KeyFlags = bit.band(self.rtg_KeyFlags, bit.bnot(16))
		elseif key == KEY_O then
			self.rtg_KeyFlags = bit.band(self.rtg_KeyFlags, bit.bnot(32))
		elseif key == KEY_K then
			self.rtg_KeyFlags = bit.band(self.rtg_KeyFlags, bit.bnot(64))
		elseif key == KEY_L then
			self.rtg_KeyFlags = bit.band(self.rtg_KeyFlags, bit.bnot(128))
		end
	end
	function Surface:Paint(w,h)
		local startX, startY = self:LocalToScreen(0, 0)
		local endX, endY = self:LocalToScreen(w, h)
		
		DisableClipping(true)
		render.SetScissorRect(startX, startY, endX, endY, true)
		
		local skillsToBeam = {}
		for k,v in pairs(self.rtg_SkillButtons) do
			if v:IsVisible() then
				skillsToBeam[k] = v
			end
		end
		for k,v in pairs(skillsToBeam) do
			for k2,v2 in pairs(skills[k].links) do
				if not skillsToBeam[k2] or k > k2 then
					self:DrawSkillBeam(k, k2)
				end
			end
		end
		for k,v in pairs(skillsToBeam) do
			v:PaintManual()
		end
		
		render.SetScissorRect(startX, startY, endX, endY, false)
		DisableClipping(false)
		
		local skillPoints = ply:RTG_GetSkillPoints()
		SKILL_LEFT_TEXTS[1] = ROTGB_LocalizeMulticoloredString(
			"rotgb_tg.skills.skill_points",
			{string.Comma(skillPoints)},
			color_white,
			{skillPoints > 0 and color_yellow or color_white}
		)
		
		local delta = RealTime() % 2
		if delta > 1 then
			delta = 2 - delta
		end
		SKILL_LEFT_TEXTS[2][1] = Color(255, 255 * delta * delta, 0)
		
		for i,v in ipairs(SKILL_LEFT_TEXTS) do
			draw.MultiColoredText(v, "rotgb_skill_body", 0, FONT_SKILL_BODY_HEIGHT*(i-1))
		end
		for i,v in ipairs(SKILL_RIGHT_TEXTS) do
			draw.MultiColoredText(v, "rotgb_skill_body", w, FONT_SKILL_BODY_HEIGHT*(i-1), TEXT_ALIGN_RIGHT)
		end
	end
	function Surface:Think()
		local x,y = self:CursorPos()
		if self.rtg_DragPos then
			self:DragSkillWeb(x-self.rtg_DragPos[1], y-self.rtg_DragPos[2])
			self.rtg_DragPos:SetUnpacked(x,y)
		end
		if self.rtg_ZoomPos then
			self:ZoomSkillWeb(x-self.rtg_ZoomPos[1], y-self.rtg_ZoomPos[2])
			self.rtg_ZoomPos:SetUnpacked(x,y)
		end
		if bit.band(self.rtg_KeyFlags, 255) ~= 0 then
			local rft = RealFrameTime()
			if bit.band(self.rtg_KeyFlags, 1) ~= 0 then
				self:DragSkillWeb(0, 1e3*rft)
			end
			if bit.band(self.rtg_KeyFlags, 2) ~= 0 then
				self:DragSkillWeb(1e3*rft, 0)
			end
			if bit.band(self.rtg_KeyFlags, 4) ~= 0 then
				self:DragSkillWeb(0, -1e3*rft)
			end
			if bit.band(self.rtg_KeyFlags, 8) ~= 0 then
				self:DragSkillWeb(-1e3*rft, 0)
			end
			if bit.band(self.rtg_KeyFlags, 16) ~= 0 then
				self:ZoomSkillWeb(0, -250*rft)
			end
			if bit.band(self.rtg_KeyFlags, 32) ~= 0 then
				self:ZoomSkillWeb(0, 250*rft)
			end
			if bit.band(self.rtg_KeyFlags, 64) ~= 0 then
				self:ZoomSkillWeb(-250*rft, 0)
			end
			if bit.band(self.rtg_KeyFlags, 128) ~= 0 then
				self:ZoomSkillWeb(250*rft, 0)
			end
		end
	end
	function Surface:PerformLayout(w, h)
		self.rtg_CenterOffset:SetUnpacked(w/2,h/2)
		self:ReloadSkillPositions(w, h)
		if self:IsSkillTooltipVisible() then
			self:RepositionSkillTooltip()
		end
	end
	
	
	
	function Surface:DragSkillWeb(dX, dY)
		self.rtg_Offset:AddUnpacked(dX, dY)
		self:InvalidateLayout()
	end
	function Surface:ZoomSkillWeb(dX, dY)
		local turningAngle = dX/200
		local zoomAmount = dY/200
		
		self.rtg_Offset:Rotate(turningAngle)
		self.rtg_Radians = self.rtg_Radians + turningAngle
		
		self.rtg_LnScale = self.rtg_LnScale - zoomAmount
		self.rtg_Offset:Multiply(math.exp(-zoomAmount))
		self:InvalidateLayout()
	end
	function Surface:ResetSkillWebCamera()
		self.rtg_Offset:SetUnpacked(0, 0)
		self.rtg_Radians = 0
		self.rtg_LnScale = 0
		self:InvalidateLayout()
	end
	
	function Surface:OnSkillHovered(skillID)
		hoveredSkillID = skillID
		self:ShowSkillTooltip()
		self:UpdateSkillTooltip(skillID)
	end
	function Surface:OnSkillUnhovered(skillID)
		self:HideSkillTooltip()
	end
	function Surface:ShowSkillTooltip()
		if IsValid(self.rtg_SkillTooltip) then
			self.rtg_SkillTooltip:Show()
		else
			self.rtg_SkillTooltip = CreateSkillTooltip(self)
		end
	end
	function Surface:HideSkillTooltip()
		self.rtg_SkillTooltip:Hide()
	end
	function Surface:IsSkillTooltipVisible()
		return IsValid(self.rtg_SkillTooltip) and self.rtg_SkillTooltip:IsVisible()
	end
	function Surface:UpdateSkillTooltip(skillID)
		self.rtg_SkillTooltip:Update(skills, skillID)
		
		--[=[local maxWidth = 0
		tooltip.rtg_SkillTier = skill.tier
		local tierPalette = SKILL_TOOLTIP_TIERS[tooltip.rtg_SkillTier+1]
		
		tooltip.rtg_SkillID = skillID
		tooltip.rtg_TitleText:SetText(skill.name)
		tooltip.rtg_TitleText:SetTextColor(tierPalette[2])
		tooltip.rtg_TitleText:SizeToContentsX()
		maxWidth = math.max(maxWidth, tooltip.rtg_TitleText:GetWide())
		--[[tooltip.rtg_TierText:SetText(tierPalette[1])
		tooltip.rtg_TierText:SetTextColor(color_white)
		tooltip.rtg_TierText:SizeToContentsX()
		maxWidth = math.max(maxWidth, tooltip.rtg_TierText:GetWide())]]
		
		for k,v in pairs(tooltip.rtg_DescTexts) do
			v:Remove()
		end
		table.Empty(tooltip.rtg_DescTexts)
		
		local traits = istable(skill.trait) and skill.trait or {skill.trait}
		local amounts = istable(skill.trait) and skill.amount or {skill.amount}
		surface.SetFont("rotgb_skill_body")
		for k,v in pairs(traits) do
			local textPanel = vgui.Create("DPanel", tooltip)
			textPanel:SetPos(SKILL_TOOLTIP_PADDING, SKILL_TOOLTIP_PADDING+FONT_SKILL_BODY_HEIGHT*k)
			textPanel.rtg_Texts = {}
			textPanel.amounts = istable(amounts[k]) and amounts[k] or {amounts[k]}
			
			-- FIXME: if "{1}" eventually does get added, this part needs to be improved
			local traitText = traitsText[v]
			if traitText then 
				local pos2,pos3 = string.find(traitText, "{0}")
				local borders = {1,pos2,pos3 and pos3+1}
				
				for k2,v2 in pairs(borders) do
					local nextBorder = borders[k2+1]
					local subtext = string.sub(traitText, v2, (nextBorder or 0)-1)
					
					if k2%2==0 then
						textPanel.rtg_Texts[k2] = string.format("%+.2f", textPanel.amounts[k2/2])
					else
						textPanel.rtg_Texts[k2] = subtext
					end
				end
			else
				textPanel.rtg_Texts[1] = "No trait description found! Trait: "..v
			end
			
			function textPanel:Paint(w,h)
				surface.SetFont("rotgb_skill_body")
				surface.SetTextPos(0,0)
				for i,v2 in ipairs(self.rtg_Texts) do
					if i%2==0 then
						surface.SetTextColor(color_yellow)
					else
						surface.SetTextColor(color_white)
					end
					surface.DrawText(v2)
				end
			end
			
			tooltip.rtg_DescTexts[k] = textPanel
			textPanel:SetSize(surface.GetTextSize(table.concat(textPanel.rtg_Texts)))
			maxWidth = math.max(maxWidth, textPanel:GetWide())
		end
		
		tooltip:SetSize(maxWidth+SKILL_TOOLTIP_PADDING*2, FONT_SKILL_BODY_HEIGHT*(1+#traits)+SKILL_TOOLTIP_PADDING*2)]=]
		self:RepositionSkillTooltip()
	end
	function Surface:RepositionSkillTooltip()
		local skillTooltip = self.rtg_SkillTooltip
		local skillButton = self.rtg_SkillButtons[hoveredSkillID]
		local radius = SKILL_SPRITE_RADIUS_MULTIPLIERS[skillTooltip.rtg_SkillTier+1]
		local buttonX, buttonY, buttonW, buttonH = skillButton:GetBounds()
		
		local posX = buttonX + buttonW * (radius+1)/2
		local posY = buttonY + buttonH * (radius+1)/2
		
		if skillTooltip:GetWide() < self:GetWide() and posX + skillTooltip:GetWide() > self:GetWide() then
			posX = posX - buttonW * radius - skillTooltip:GetWide()
		end
		if skillTooltip:GetTall() < self:GetTall() and posY + skillTooltip:GetTall() > self:GetTall() then
			posY = posY - buttonH * radius - skillTooltip:GetTall()
		end
		
		--[[local flipX = buttonX >= (self:GetWide() - buttonW) / 2
		local flipY = buttonY >= (self:GetTall() - buttonH) / 2
		
		local xOffset = buttonW * (flipX and 0 or 1)
		local yOffset = buttonH * (flipY and 0 or 1)
		
		local xPos = buttonX - (flipX and skillTooltip:GetWide() or 0) + xOffset
		local yPos = buttonY - (flipY and skillTooltip:GetTall() or 0) + yOffset]]
		
		skillTooltip:SetPos(posX, posY)
	end
	
	function Surface:GetSkillMaterial(skillID)
		local skillMaterialTable = SKILL_MATERIALS[skills[skillID].tier+1]
		if ply:RTG_HasSkill(skillID) then return skillMaterialTable.acquired
		elseif ply:RTG_SkillUnlocked(skillID, skills) then return skillMaterialTable.unlocked
		else return skillMaterialTable.locked
		end
	end
	function Surface:GetSkillPositionAndAngles(skill)
		if not self.rtg_SkillPositionData[skill] then
			local skillTable = skills[skill]
			local skillAngle, skillPosition
			if skillTable.parent then
				skillAngle, skillPosition = unpack(self:GetSkillPositionAndAngles(skillTable.parent))
			else
				skillAngle, skillPosition = 0, VectorTable(0,0)
			end
			skillAngle = skillAngle + math.rad(skillTable.ang)
			skillPosition = skillPosition + skillTable.pos:GetRotated(skillAngle)
			self.rtg_SkillPositionData[skill] = {skillAngle, skillPosition}
		end
		return self.rtg_SkillPositionData[skill]
	end
	function Surface:ReloadSkillPositions(w, h)
		local scale = math.exp(self.rtg_LnScale)
		local newSize = SKILL_SIZE*scale
		for k,v in pairs(skills) do
			local angle, position = unpack(self:GetSkillPositionAndAngles(k))
			position = position:GetRotated(self.rtg_Radians)
			position:Multiply(newSize)
			position:Add(self.rtg_Offset)
			position:Add(self.rtg_CenterOffset)
			position:SubtractDistributed(newSize/2)
			local skillButton = self.rtg_SkillButtons[k]
			if IsValid(skillButton) then
				if position:WithinBox(-newSize, w, -newSize, h) ~= skillButton:IsVisible() then
					if skillButton:IsVisible() then
						skillButton:Hide()
					else
						skillButton:Show()
					end
				end
				skillButton:MoveToPositionAndSize(position, newSize)
			end
		end
	end
	function Surface:DrawSkillBeam(skillID, skillID2)
		local skillButton, skillButton2 = self.rtg_SkillButtons[skillID], self.rtg_SkillButtons[skillID2]
		
		local pos1 = skillButton:GetVectorTablePos()
		local pos2 = skillButton2:GetVectorTablePos()
		
		local drawPos = pos1:Lerp(0.5, pos2)
		local x, y = drawPos[1], drawPos[2]
		local width, length, rot = skillButton:GetWide()*SKILL_BEAM_WIDTH_MULTIPLIER, pos1:Distance(pos2), math.deg(pos1:Bearing(pos2))
		local beamPhase = skillID > skillID2 and skillButton.rtg_BeamPhase or skillButton2.rtg_BeamPhase
		local alpha = math.Remap(math.sin(RealTime()*SKILL_BEAM_SPEED_MULTIPLIER+beamPhase), -1, 1, SKILL_BEAM_SMOOTH_ALPHA_MIN, SKILL_BEAM_SMOOTH_ALPHA_MAX)
		
		surface.SetDrawColor(alpha,alpha,alpha)
		surface.SetMaterial(SKILL_MATERIALS.beam)
		surface.DrawTexturedRectRotated(x, y, width, length, rot)
		surface.DrawTexturedRectRotated(x, y, width, length, rot+180)
	end
	function Surface:ActivatePerk(skillID)
		local button = self.rtg_SkillButtons[skillID]
		if IsValid(button) then
			button:ActivatePerk()
		end
	end
	
	return Surface
end

local function CreateSkillWebButtonsPanel(parent)
	local effectsButton = CreateButton(nil, "#rotgb_tg.buttons.skills.skill_effects", color_aqua, function()
		parent:CreateSkillSummary()
	end)
	local cameraButton = CreateButton(nil, "#rotgb_tg.buttons.skills.reset_camera", color_green, function()
		parent:ResetSkillWebCamera()
	end)
	local resetButton = CreateButton(nil, "#rotgb_tg.buttons.skills.reset_skills", color_red, function()
		if next(LocalPlayer():RTG_GetSkills()) then
			Derma_Query("#rotgb_tg.buttons.skills.reset_skills.warning", "#rotgb_tg.skills.reset_skills", "#GameUI_Yes", function()
				net.Start("rotgb_gamemode")
				net.WriteUInt(RTG_OPERATION_SKILLS, 4)
				net.WriteUInt(RTG_SKILL_CLEAR, 2)
				net.SendToServer()
			end, "#GameUI_No")
		end
	end)
	local backButton = CreateButton(nil, "#rotgb_tg.buttons.back", color_yellow, function()
		hook.Run("HideSkillWeb")
	end)
	local Panel = CreateHorizontalPanelContainer(parent, {effectsButton, cameraButton, backButton, resetButton}, FONT_HEADER_HEIGHT)
	Panel:Dock(BOTTOM)
	
	return Panel
end

local function DrawAchievementPanel(panel, w, h)
	local drawColor = hook.Run("IsAchievementUnlocked", panel.rotgb_AchievementID) and color_green_semitransparent or color_gray_semitransparent
	draw.RoundedBox(ACHIEVEMENT_PADDING,0,0,w,h,drawColor)
end

local function DrawAchievementProgress(panel, w, h)
	local achievementUnlocked = hook.Run("IsAchievementUnlocked", panel.rotgb_AchievementID)
	local progress = LocalPlayer():RTG_GetStat(panel.rotgb_Criteria)
	local progressDisplay = panel.rotgb_Display == 1 and ROTGB_FormatCash(progress) or string.Comma(progress)
	local maxProgressDisplay = panel.rotgb_Display == 1 and ROTGB_FormatCash(panel.rotgb_MaxProgress, true) or string.Comma(panel.rotgb_MaxProgress)
	
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, w, h)
	
	if achievementUnlocked then
		surface.SetDrawColor(127, 255, 127, 255)
		surface.DrawRect(2, 2, w-4, h-4)
		
		local achievementProgressText = ROTGB_LocalizeString("rotgb_tg.achievement.progress", progressDisplay, maxProgressDisplay)
		draw.SimpleTextOutlined(achievementProgressText, "rotgb_achievement_body", w/2, h/2, color_light_green, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
	else
		surface.SetDrawColor(127, 0, 255, 255)
		surface.DrawRect(2, 2, (w-4)*math.min(progress/panel.rotgb_MaxProgress,1), h-4)
		
		local achievementProgressText = ROTGB_LocalizeString("rotgb_tg.achievement.progress", progressDisplay, maxProgressDisplay)
		draw.SimpleTextOutlined(achievementProgressText, "rotgb_achievement_body", w/2, h/2, color_purple, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
	end
end

local function CreateAchievementPanel(parent, achievementID)
	local achievement = hook.Run("GetAchievements")[achievementID]
	local name = achievement.name
	
	local panel = vgui.Create("DPanel", parent)
	panel:SetTall(ACHIEVEMENT_SIZE)
	panel:SetZPos(achievementID)
	panel:DockMargin(0,0,0,ACHIEVEMENT_PADDING)
	panel:Dock(TOP)
	panel:DockPadding(ACHIEVEMENT_PADDING, ACHIEVEMENT_PADDING, ACHIEVEMENT_PADDING, ACHIEVEMENT_PADDING)
	panel.rotgb_AchievementID = achievementID
	panel.Paint = DrawAchievementPanel
	
	local achievementImage = vgui.Create("DImage", panel)
	achievementImage:SetWide(ACHIEVEMENT_SIZE - ACHIEVEMENT_PADDING * 2)
	achievementImage:SetZPos(1)
	achievementImage:DockMargin(0,0,ACHIEVEMENT_PADDING,0)
	achievementImage:Dock(LEFT)
	achievementImage:SetImage("rotgb_the_gamemode/achievements/"..name..".png")
	
	local achievementHeader = vgui.Create("DPanel", panel)
	achievementHeader:SetTall(FONT_ACHIEVEMENT_HEADER_HEIGHT)
	achievementHeader:SetZPos(2)
	achievementHeader:DockMargin(0,0,0,ACHIEVEMENT_PADDING)
	achievementHeader:Dock(TOP)
	achievementHeader.Paint = nil
	
	local achievementXP = vgui.Create("DLabel", achievementHeader)
	achievementXP:SetFont("rotgb_achievement_header")
	achievementXP:SetTextColor(color_purple)
	achievementXP:SetText(ROTGB_LocalizeString("rotgb_tg.achievement.reward",
		ROTGB_LocalizeString("rotgb_tg.achievement.reward.xp", string.Comma(achievement.xp))
	))
	achievementXP:SizeToContentsX()
	achievementXP:Dock(RIGHT)
	achievementXP.rotgb_AchievementID = achievementID
	local oldThink = achievementXP.Think
	function achievementXP:Think(...)
		local unlocked = hook.Run("IsAchievementUnlocked", achievementID)
		if unlocked ~= self.rotgb_AchievementAchieved then
			self.rotgb_AchievementAchieved = unlocked
			self:SetTextColor(unlocked and color_light_green or color_purple)
		end
		if oldThink then
			oldThink(self, ...)
		end
	end
	
	local achievementTitle = vgui.Create("DLabel", achievementHeader)
	achievementTitle:SetFont("rotgb_achievement_header")
	achievementTitle:SetTextColor(ACHIEVEMENT_TIERS[(tonumber(achievement.tier) or 1)] or color_light_red)
	achievementTitle:SetText("#rotgb_tg.achievement."..name..".name")
	achievementTitle:Dock(FILL)
	
	local achievementProgress = vgui.Create("DPanel", panel)
	achievementProgress:SetTall(FONT_ACHIEVEMENT_BODY_HEIGHT+8)
	achievementProgress:SetZPos(2)
	achievementProgress:DockMargin(0,ACHIEVEMENT_PADDING,0,0)
	achievementProgress:Dock(BOTTOM)
	achievementProgress.rotgb_AchievementID = achievementID
	achievementProgress.rotgb_Criteria = achievement.criteria
	achievementProgress.rotgb_MaxProgress = achievement.amount
	achievementProgress.rotgb_Display = achievement.display
	achievementProgress.Paint = DrawAchievementProgress
	
	local achievementDescription = vgui.Create("DLabel", panel)
	achievementDescription:SetFont("rotgb_achievement_body")
	achievementDescription:SetTextColor(color_white)
	achievementDescription:SetText("#rotgb_tg.achievement."..name..".description")
	achievementDescription:SetWrap(true)
	achievementDescription:SetContentAlignment(7)
	achievementDescription:Dock(FILL)
	
	return panel
end

local function CreateAchievementsPanel(parent)
	local panel = vgui.Create("DPanel", parent)
	panel:Dock(FILL)
	panel.Paint = nil
	
	local searchBar = vgui.Create("DTextEntry", panel)
	searchBar:SetTall(FONT_BODY_HEIGHT)
	searchBar:SetFont("rotgb_body")
	searchBar:SetPlaceholderText("#rotgb_tg.achievement.search")
	searchBar:Dock(TOP)
	
	local achievementsPanel = vgui.Create("DScrollPanel", panel)
	achievementsPanel:DockMargin(0, ACHIEVEMENT_PADDING, 0, ACHIEVEMENT_PADDING)
	achievementsPanel:Dock(FILL)
	achievementsPanel:DockPadding(ACHIEVEMENT_PADDING, ACHIEVEMENT_PADDING, ACHIEVEMENT_PADDING, 0)
	achievementsPanel.rotgb_FilterString = ""
	achievementsPanel.rotgb_AchievementPanels = {}
	function achievementsPanel:Refresh()
		for k,v in pairs(self.rotgb_AchievementPanels) do
			v:Remove()
		end
		for i,v in ipairs(hook.Run("GetAchievements")) do
			local searchPhrase = string.lower(language.GetPhrase("rotgb_tg.achievement."..v.name..".name")..language.GetPhrase("rotgb_tg.achievement."..v.name..".description"))
			if self.rotgb_FilterString == "" or string.find(searchPhrase, string.lower(self.rotgb_FilterString), 1, true) then
				table.insert(self.rotgb_AchievementPanels, CreateAchievementPanel(achievementsPanel, i))
			end
		end
	end
	function searchBar:OnChange()
		achievementsPanel.rotgb_FilterString = self:GetValue()
		achievementsPanel:Refresh()
	end
	achievementsPanel:Refresh()
	
	return panel
end



function GM:CreateStartupMenu()
	local Menu = CreateMenu()
	if ROTGB_SetCash then
		CreateHeader(Menu, 1, "#rotgb_tg.welcome.header")
		CreateText(Menu, 2, "#rotgb_tg.welcome.1")
		CreateText(Menu, 3, "#rotgb_tg.welcome.2")
		CreateText(Menu, 4, "#rotgb_tg.welcome.3")
		CreateText(Menu, 5, "#rotgb_tg.welcome.4")
		CreateText(Menu, 6, "#rotgb_tg.welcome.5")
		CreateText(Menu, 7, "#rotgb_tg.welcome.6")
		CreateText(Menu, 8, "#rotgb_tg.welcome.7")
		CreateText(Menu, 9, "#rotgb_tg.welcome.8")
		CreateText(Menu, 10, "#rotgb_tg.welcome.9")
		CreateText(Menu, 11, "#rotgb_tg.welcome.10")
		CreateText(Menu, 12, "#rotgb_tg.welcome.11")
		CreateText(Menu, 13, "#rotgb_tg.welcome.12")
		CreateText(Menu, 14, "#rotgb_tg.welcome.13")
		CreateText(Menu, 15, "#rotgb_tg.welcome.14")
		CreateText(Menu, 16, "#rotgb_tg.welcome.15")
		
		local NextButton = CreateButton(Menu, "#rotgb_tg.buttons.proceed", color_green, function()
			hook.Run("ShowHelp")
		end)
		NextButton:SetPos(Menu:GetWide()-NextButton:GetWide()-indentX, Menu:GetTall()-NextButton:GetTall()-indentY)
	else
		CreateHeader(Menu, 1, "#rotgb_tg.rotgb_missing.header")
		CreateText(Menu, 2, "#rotgb_tg.rotgb_missing.1")
		CreateText(Menu, 3, "#rotgb_tg.rotgb_missing.2")
		
		local OpenButton = CreateButton(Menu, "#rotgb_tg.buttons.rotgb_addon", color_green, function()
			steamworks.ViewFile("1616333917")
		end)
		OpenButton:SetPos(Menu:GetWide()-OpenButton:GetWide()-indentX, Menu:GetTall()-OpenButton:GetTall()-indentY)
	end
	
	return Menu
end

function GM:CreateTeamSelectMenu()
	local Menu = CreateMenu()
	CreateHeader(Menu, 1, "#rotgb_tg.teams.header")
	
	if LocalPlayer():Team()~=TEAM_UNASSIGNED and LocalPlayer():Team()~=TEAM_SPECTATOR then
		local WarningText = CreateText(Menu, 2, "#rotgb_tg.teams.change_warning")
		function WarningText:DoFlashAnim()
			WarningText.anim = WarningText:NewAnimation(2, 0, 1, function(anim, panel)
				panel:DoFlashAnim()
			end)
			WarningText.anim.Think = function(anim, panel, frac)
				local delta = frac * 2
				if delta > 1 then
					delta = 2 - delta
				end
				delta = delta * delta
				panel:SetTextColor(Color(255, 255 * delta, 0))
			end
		end
		WarningText:DoFlashAnim()
	end
	
	local Divider = vgui.Create("DHorizontalDivider", Menu)
	Divider:Dock(FILL)
	local LeftPanel = CreateTeamLeftPanel()
	local RightPanel = CreateTeamRightPanel()
	function LeftPanel:OnTeamHovered(teamID)
		RightPanel:OnTeamHovered(teamID)
	end
	Divider:SetLeft(LeftPanel)
	Divider:SetRight(RightPanel)
	Divider:SetDividerWidth(FONT_HEADER_HEIGHT)
	Divider:SetLeftWidth((Menu:GetWide()-FONT_HEADER_HEIGHT)/2-indentX)
	
	return Menu
end

function GM:CreateScoreboard()
	local Menu = CreateMenu()
	
	local difficulty = hook.Run("GetDifficulty")
	if (difficulty and GAMEMODE.Modes[difficulty]) then
		CreateHeader(Menu, 1, ROTGB_LocalizeString(
			"rotgb_tg.scoreboard.header",
			language.GetPhrase("rotgb_tg.scoreboard.title"),
			ROTGB_LocalizeString(
				"rotgb_tg.difficulty.subcategory",
				language.GetPhrase("rotgb_tg.difficulty.category."..GAMEMODE.Modes[difficulty].category),
				language.GetPhrase("rotgb_tg.difficulty."..difficulty..".name")
			)
		))
	else
		CreateHeader(Menu, 1, ROTGB_LocalizeString("rotgb_tg.scoreboard.header.no_difficulty", language.GetPhrase("rotgb_tg.scoreboard.title")))
	end
	
	function Menu:RecreateScoreboard()
		if IsValid(self.Scoreboard) then
			self.Scoreboard:Remove()
		end
		self.Scoreboard = CreateScoreboardPanel(self)
	end
	Menu:RecreateScoreboard()
	
	return Menu
end

function GM:CreateSuccessMenu()
	local Menu = CreateMenu()
	Menu:SetKeyboardInputEnabled(false)
	
	local flawless = true
	for k,v in pairs(ents.FindByClass("gballoon_target")) do
		if not v:GetNonVital() and v:GetMaxHealth() > v:Health() then
			flawless = false
		end
	end
	local Header = CreateHeader(Menu, 1, flawless and "#rotgb_tg.result_screen.flawless_victory" or "#rotgb_tg.result_screen.victory")
	Header:SetTextColor(color_light_green)
	
	CreateScoreboardPanel(Menu)
	CreateGameOverButtons(Menu, true)
	
	return Menu
end

function GM:CreateFailureMenu()
	local Menu = CreateMenu()
	Menu:SetKeyboardInputEnabled(false)
	
	local flawless = true
	for k,v in pairs(player.GetAll()) do
		if (v.rtg_gBalloonPops or 0) > 0 then
			flawless = false
		end
	end
	local Header = CreateHeader(Menu, 1, flawless and "#rotgb_tg.result_screen.flawless_defeat" or "#rotgb_tg.result_screen.defeat")
	Header:SetTextColor(color_light_red)
	
	CreateScoreboardPanel(Menu)
	CreateGameOverButtons(Menu)
	
	return Menu
end

function GM:CreateDifficultyMenu(disableCancel)
	if LocalPlayer():IsAdmin() then
		local Menu = CreateMenu()
		CreateHeader(Menu, 0, "#rotgb_tg.difficulty.header")
		local DifficultySelectionPanel = CreateDifficultySelectionPanel(Menu)
		local ConfirmButtonPanel = CreateDifficultyConfirmButtonPanel(Menu, DifficultySelectionPanel, 2)
		if not disableCancel then
			local CancelButton = CreateDifficultyCancelButtonPanel(Menu, 1)
		end
		
		return Menu
	else
		ROTGB_LogError("This concommand is only available to admins.","")
	end
end

function GM:CreateVoteMenu(data)
	local Menu = CreateMenu()
	
	local VoteLeftPanel = CreateVoteLeftPanel()
	local VoteRightPanel = CreateVoteRightPanel(VoteLeftPanel, data)
	local VoteReasonPanel = CreateVoteReasonPanel()
	local VoteStartPanel = CreateVoteButtonPanel(Menu, VoteRightPanel, VoteReasonPanel, data)
	
	local ButtonDivider = vgui.Create("DVerticalDivider", Menu)
	local ReasonDivider = vgui.Create("DVerticalDivider")
	local LeftRightDivider = vgui.Create("DHorizontalDivider")
	
	local buttonDividerTopHeight = Menu:GetTall()-indentY*2-VoteStartPanel:GetTall()-FONT_BODY_HEIGHT
	local reasonDividerTopHeight = buttonDividerTopHeight-VoteReasonPanel:GetTall()-FONT_BODY_HEIGHT
	local leftRightDividerLeftWidth = (Menu:GetWide()-FONT_BODY_HEIGHT)/2-indentX
	
	ButtonDivider:SetDividerHeight(FONT_BODY_HEIGHT)
	ButtonDivider:Dock(FILL)
	ButtonDivider:SetTop(ReasonDivider)
	ButtonDivider:SetBottom(VoteStartPanel)
	ButtonDivider:SetTopHeight(buttonDividerTopHeight)
	
	ReasonDivider:SetDividerHeight(FONT_BODY_HEIGHT)
	ReasonDivider:SetTop(LeftRightDivider)
	ReasonDivider:SetBottom(VoteReasonPanel)
	ReasonDivider:SetTopHeight(reasonDividerTopHeight)
	
	LeftRightDivider:SetDividerWidth(FONT_BODY_HEIGHT)
	LeftRightDivider:SetLeft(VoteLeftPanel)
	LeftRightDivider:SetRight(VoteRightPanel)
	LeftRightDivider:SetLeftWidth(leftRightDividerLeftWidth)
	
	function Menu:UpdateRightPanel(typ)
		VoteLeftPanel:UpdateRightPanel(typ)
	end
	
	return Menu
end

function GM:CreateVoterMenu()
	local voteInfo = hook.Run("GetCurrentVote")
	
	local SideMenu = CreateMenu()
	SideMenu:SetSize(ScrW()/6, ScrH()/3)
	SideMenu:SetPos(FONT_BODY_HEIGHT, ScrH()/3)
	SideMenu:DockPadding(FONT_BODY_HEIGHT/2, FONT_BODY_HEIGHT/2, FONT_BODY_HEIGHT/2, FONT_BODY_HEIGHT/2)
	SideMenu:KillFocus()
	SideMenu:SetKeyboardInputEnabled(false)
	SideMenu:SetMouseInputEnabled(false)
	
	local statement = CreateVoterStatementPanel(SideMenu, voteInfo)
	local timer = CreateVoterTimerPanel(SideMenu, 2, voteInfo)
	local indicators = CreateVoterIndicatorsPanel(SideMenu, 1, voteInfo)
	
	function SideMenu:SetValues(yes, no)
		indicators:SetValues(yes, no)
	end
	function SideMenu:ApplyResult(voteInfo, result)
		statement:Remove()
		timer:Remove()
		indicators:Remove()
		
		CreateVoterResultStatementHeader(self, voteInfo, result)
		CreateVoterResultStatementPanel(self, voteInfo, result)
		self:RemoveAfterDelay(5)
	end
	
	LocalPlayer():AddPlayerOption("rotgb_vote", voteInfo.expiry-RealTime(), VoterCallback)
	
	return SideMenu
end

function GM:CreateSkillWebMenu()
	local Menu = CreateMenu()
	
	function Menu:CreateSkillWebSurface()
		if IsValid(self.rtg_skillSummaryPanel) then
			self.rtg_skillSummaryPanel:Remove()
		end
		if IsValid(self.rtg_skillSummaryBackButton) then
			self.rtg_skillSummaryBackButton:Remove()
		end
		
		if IsValid(self.rtg_skillTreeSurface) then
			self.rtg_skillTreeSurface:Show()
		else
			self.rtg_skillTreeSurface = CreateSkillWebSurface(Menu)
		end
		if IsValid(self.rtg_skillTreeButtons) then
			self.rtg_skillTreeButtons:Show()
		else
			self.rtg_skillTreeButtons = CreateSkillWebButtonsPanel(Menu)
		end
	end
	function Menu:CreateSkillSummary()
		if IsValid(self.rtg_skillTreeSurface) then
			self.rtg_skillTreeSurface:Hide()
		end
		if IsValid(self.rtg_skillTreeButtons) then
			self.rtg_skillTreeButtons:Hide()
		end
		
		self.rtg_skillSummaryPanel = CreateSkillSummaryPanel(Menu)
		self.rtg_skillSummaryBackButton = CreateSkillSummaryBackButton(Menu)
	end
	function Menu:ActivatePerk(...)
		self.rtg_skillTreeSurface:ActivatePerk(...)
	end
	function Menu:ResetSkillWebCamera(...)
		self.rtg_skillTreeSurface:ResetSkillWebCamera(...)
	end
	function Menu:OnKeyCodePressed(...)
		self.rtg_skillTreeSurface:OnKeyCodePressed(...)
	end
	function Menu:OnKeyCodeReleased(...)
		self.rtg_skillTreeSurface:OnKeyCodeReleased(...)
	end
	Menu:CreateSkillWebSurface()
	
	return Menu
end

function GM:CreateAchievementsMenu()
	local Menu = CreateMenu()
	
	CreateHeader(Menu, 1, "#rotgb_tg.achievement.header")
	CreateText(Menu, 2, "#rotgb_tg.achievement.freeplay")
	CreateAchievementsPanel(Menu)
	
	local backButton = CreateButton(nil, "#rotgb_tg.buttons.back", color_yellow, function()
		hook.Run("HideAchievementsMenu")
	end)
	local backButtonCenteringPanel = CreateElementCenteringPanel(backButton, Menu)
	backButtonCenteringPanel:Dock(BOTTOM)
	
	return Menu
end



function GM:ShowHelp()
	if IsValid(hook.Run("GetStartupMenu")) then
		hook.Run("GetStartupMenu"):Close()
		if hook.Run("GetStartupState")<1 then
			hook.Run("SetStartupState", 1)
		end
	else
		hook.Run("SetStartupMenu", hook.Run("CreateStartupMenu"))
	end
end

function GM:ShowTeam()
	hook.Run("HideTeam")
	hook.Run("SetTeamSelectionMenu", hook.Run("CreateTeamSelectMenu"))
end

function GM:HideTeam()
	if IsValid(hook.Run("GetTeamSelectionMenu")) then
		hook.Run("GetTeamSelectionMenu"):Close()
		if hook.Run("GetStartupState")<3 then
			hook.Run("SetStartupState", 3)
		end
	end
end

function GM:ScoreboardShow()
	hook.Run("ScoreboardHide")
	self.ScoreboardFrame = hook.Run("CreateScoreboard")
end

function GM:ScoreboardHide()
	if IsValid(self.ScoreboardFrame) then
		self.ScoreboardFrame:Close()
	end
end

function GM:GetGamemodeDifficultyNodes()
	local nodesByCategory = {}
	for k,v in pairs(self.Modes) do
		if v.category then
			local subnode = {
				name = k,
				place = v.place
			}
			nodesByCategory[v.category] = nodesByCategory[v.category] or {}
			table.insert(nodesByCategory[v.category], subnode)
		end
	end
	
	for k,v in pairs(nodesByCategory) do
		table.SortByMember(v, "place", true)
	end
	
	local nodes = {}
	for k,v in pairs(nodesByCategory) do
		local node = {
			name = k,
			place = self.ModeCategories[k],
			subnodes = nodesByCategory[k]
		}
		table.insert(nodes, node)
	end
	
	table.SortByMember(nodes, "place", true)
	return nodes
end

function GM:ShowDifficultySelection(disableCancel)
	hook.Run("HideDifficultySelection")
	hook.Run("SetDifficultySelectionMenu", hook.Run("CreateDifficultyMenu", disableCancel))
end

function GM:HideDifficultySelection()
	if IsValid(hook.Run("GetDifficultySelectionMenu")) then
		hook.Run("GetDifficultySelectionMenu"):Close()
		if hook.Run("GetStartupState")<2 then
			hook.Run("SetStartupState", 2)
		end
	end
end

function GM:ShowVoteMenu(data)
	if IsValid(hook.Run("GetVoteMenu")) then
		hook.Run("GetVoteMenu"):Close()
	end
	hook.Run("SetVoteMenu", hook.Run("CreateVoteMenu", data))
end

function GM:ShowVoterMenu()
	if IsValid(hook.Run("GetVoterMenu")) then
		hook.Run("GetVoterMenu"):Close()
	end
	hook.Run("SetVoterMenu", hook.Run("CreateVoterMenu"))
end

function GM:ShowSkillWeb()
	if IsValid(hook.Run("GetSkillWebMenu")) then
		hook.Run("GetSkillWebMenu"):Show()
	else
		hook.Run("SetSkillWebMenu", hook.Run("CreateSkillWebMenu"))
	end
end

function GM:HideSkillWeb()
	if IsValid(hook.Run("GetSkillWebMenu")) then
		hook.Run("GetSkillWebMenu"):Hide()
	end
end

function GM:ShowAchievementsMenu()
	if IsValid(hook.Run("GetAchievementsMenu")) then
		hook.Run("GetAchievementsMenu"):Show()
	else
		hook.Run("SetAchievementsMenu", hook.Run("CreateAchievementsMenu"))
	end
end

function GM:HideAchievementsMenu()
	if IsValid(hook.Run("GetAchievementsMenu")) then
		hook.Run("GetAchievementsMenu"):Hide()
	end
end