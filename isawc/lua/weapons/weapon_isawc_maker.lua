AddCSLuaFile()

--SWEP.Base = "weapon_base"
SWEP.PrintName = "Container Maker"
SWEP.Category = "ISAWC"
SWEP.Author = "Piengineer"
SWEP.Contact = "http://steamcommunity.com/id/Piengineer12/"
SWEP.Purpose = "Convert a Physics Prop into an ISAWC container!"
SWEP.Instructions = "Primary Fire transforms a prop into a container. Secondary Fire does the opposite. Reload to view options."
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
--SWEP.ViewModel = "models/weapons/v_pistol.mdl"
--SWEP.ViewModelFOV = 62
--SWEP.ViewModelFlip = false
--SWEP.ViewModelFlip1 = false
--SWEP.ViewModelFlip2 = false
SWEP.Spawnable = true
--SWEP.AdminOnly = false
SWEP.Slot = 2
SWEP.SlotPos = 7
--SWEP.BounceWeaponIcon = true
SWEP.DrawAmmo = false
--SWEP.DrawCrosshair = true
--SWEP.AccurateCrosshair = false
--SWEP.DrawWeaponInfoBox = true
--SWEP.WepSelectIcon = surface.GetTextureID("weapons/swep")
--SWEP.SpeechBubbleLid = surface.GetTextureID("gui/speech_lid")
SWEP.AutoSwitchFrom = false
--SWEP.AutoSwitchTo = true
--SWEP.Weight = 5
--SWEP.CSMuzzleFlashes = false
--SWEP.CSMuzzleX = false
--SWEP.BobScale = 1
--SWEP.SwayScale = 1
SWEP.UseHands = true
--SWEP.m_WeaponDeploySpeed = 1
--SWEP.m_bPlayPickupSound = true
--SWEP.RenderGroup = RENDERGROUP_OPAQUE
--SWEP.ScriptedEntityType = "weapon"
--SWEP.IconOverride = "materials/entities/base.png"
--SWEP.DisableDuplicator = false
SWEP.Primary = {
	Ammo = "none",
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false
}
SWEP.Secondary = {
	Ammo = "none",
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false
}

function SWEP:SetupDataTables()
	self:NetworkVar("Float",0,"MassMul")
	self:NetworkVar("Float",1,"VolumeMul")
	self:NetworkVar("Float",2,"MassConstant")
	self:NetworkVar("Float",3,"VolumeConstant")
	self:NetworkVar("String",0,"OpenSounds")
	self:NetworkVar("String",1,"CloseSounds")
	
	self:SetMassMul(1)
	self:SetVolumeMul(1)
	self:SetMassConstant(10)
	self:SetVolumeConstant(10)
	self:SetOpenSounds("chest/open.wav")
	self:SetCloseSounds("chest/close.wav|chest/close2.wav|chest/close3.wav")
end

function SWEP:PrimaryAttack()
	self.Weapon:SetNextPrimaryFire(CurTime()+0.2)
	local ply = self:GetOwner()
	if SERVER and ply:IsPlayer() and IsFirstTimePredicted() then
		local ent = ply:GetEyeTraceNoCursor().Entity
		if (IsValid(ent) and ent:GetClass()=="prop_physics") then
			local container = ents.Create("isawc_container_template")
			container.ContainerModel = ent:GetModel()
			container.ContainerMassMul = self:GetMassMul()
			container.ContainerVolumeMul = self:GetVolumeMul()
			container.ContainerConstants = {
				Mass = self:GetMassConstant(),
				Volume = self:GetVolumeConstant()
			}
			container.OpenSounds = string.Split(self:GetOpenSounds(), '|')
			container.CloseSounds = string.Split(self:GetCloseSounds(), '|')
			container:SetPos(ent:GetPos())
			container:SetAngles(ent:GetAngles())
			container:Spawn()
			ent:Remove()
			self:EmitSound("buttons/button17.wav")
			ply:PrintMessage(HUD_PRINTTALK, "The physics prop has been turned into a transformed container!")
		else
			self:EmitSound("items/medshotno1.wav")
			ply:PrintMessage(HUD_PRINTTALK, "That is not a physics prop!")
		end
	end
end

function SWEP:SecondaryAttack()
	local ply = self:GetOwner()
	self.Weapon:SetNextSecondaryFire(CurTime()+0.2)
	if SERVER and ply:IsPlayer() and IsFirstTimePredicted() then
		local ent = ply:GetEyeTraceNoCursor().Entity
		if (IsValid(ent) and ent:GetClass()=="isawc_container_template") then
			local prop = ents.Create("prop_physics")
			prop:SetModel(ent:GetModel())
			prop:SetPos(ent:GetPos())
			prop:SetAngles(ent:GetAngles())
			prop:Spawn()
			ent:Remove()
			self:EmitSound("buttons/button17.wav")
			ply:PrintMessage(HUD_PRINTTALK, "The transformed container has been turned into a physics prop!")
		else
			self:EmitSound("items/medshotno1.wav")
			ply:PrintMessage(HUD_PRINTTALK, "That is not a transformed container!")
		end
	end
end

function SWEP:Reload()
	local ply = self:GetOwner()
	if SERVER and ply:IsPlayer() and IsFirstTimePredicted() then
		-- This is kinda bad, but it is still better than most other methods for communicating with the client
		net.Start("isawc_general")
		net.WriteString("open_maker_menu")
		net.WriteEntity(self)
		net.Send(ply)
	end
end

function SWEP:OpenMakerMenu()
	if (self.cooldown or 0) > RealTime() then return end
	
	self.cooldown = RealTime() + 1
	local massMul, volumeMul = self:GetMassMul(), self:GetVolumeMul()
	local massConstant, volumeConstant = self:GetMassConstant(), self:GetVolumeConstant()
	local openSounds, closeSounds = self:GetOpenSounds(), self:GetCloseSounds()
	--print(massMul, volumeMul, massConstant, volumeConstant, openSounds, closeSounds)
	local weapon = self
	
	local Main = vgui.Create("DFrame")
	Main:SetSize(640, 480)
	Main:Center()
	Main:MakePopup()
	
	local Label = Main:Add("DLabel")
	Label:SetText("A multiplier of 0 means infinite.")
	Label:Dock(TOP)
	
	local MassSlider = Main:Add("DNumSlider")
	MassSlider:SetText("Mass Multiplier")
	MassSlider:SetMinMax(0,10)
	MassSlider:SetDecimals(3)
	MassSlider:SetDefaultValue(1)
	MassSlider:SetValue(massMul)
	MassSlider:Dock(TOP)
	function MassSlider:OnValueChanged(value)
		massMul = value
	end
	
	local VolumeSlider = Main:Add("DNumSlider")
	VolumeSlider:SetText("Volume Multiplier")
	VolumeSlider:SetMinMax(0,10)
	VolumeSlider:SetDecimals(3)
	VolumeSlider:SetDefaultValue(1)
	VolumeSlider:SetValue(volumeMul)
	VolumeSlider:Dock(TOP)
	function VolumeSlider:OnValueChanged(value)
		volumeMul = value
	end
	
	local ConstantMassSlider = Main:Add("DNumSlider")
	ConstantMassSlider:SetText("Constant Mass (kg)")
	ConstantMassSlider:SetMinMax(0,10000)
	ConstantMassSlider:SetDecimals(0)
	ConstantMassSlider:SetDefaultValue(10)
	ConstantMassSlider:SetValue(massConstant)
	ConstantMassSlider:Dock(TOP)
	function ConstantMassSlider:OnValueChanged(value)
		massConstant = value
	end
	
	local ConstantVolumeSlider = Main:Add("DNumSlider")
	ConstantVolumeSlider:SetText("Constant Volume (dm³)")
	ConstantVolumeSlider:SetMinMax(0,10000)
	ConstantVolumeSlider:SetDecimals(0)
	ConstantVolumeSlider:SetDefaultValue(10)
	ConstantVolumeSlider:SetValue(volumeConstant)
	ConstantVolumeSlider:Dock(TOP)
	function ConstantVolumeSlider:OnValueChanged(value)
		volumeConstant = value
	end
	
	local Label = Main:Add("DLabel")
	Label:SetText("Use '|' to separate each sound. One will be selected randomly when the container is opened / closed.")
	Label:Dock(TOP)
	
	local Label = Main:Add("DLabel")
	Label:SetText("Open Sounds")
	Label:Dock(TOP)
	
	local OpenSoundsBox = Main:Add("DTextEntry")
	OpenSoundsBox:SetText(openSounds)
	OpenSoundsBox:Dock(TOP)
	function OpenSoundsBox:OnChange()
		openSounds = self:GetValue()
	end
	
	local Label = Main:Add("DLabel")
	Label:SetText("Close Sounds")
	Label:Dock(TOP)
	
	local CloseSoundsBox = Main:Add("DTextEntry")
	CloseSoundsBox:SetText(closeSounds)
	CloseSoundsBox:Dock(TOP)
	function CloseSoundsBox:OnChange()
		closeSounds = self:GetValue()
	end
	
	local AcceptButton = Main:Add("DButton")
	AcceptButton:SetText("Accept")
	AcceptButton:Dock(BOTTOM)
	function AcceptButton:DoClick()
		if not IsValid(weapon) then
			Main:Close()
			ISAWC:NoPickup("The weapon is missing!",LocalPlayer())
		elseif weapon.cooldown <= RealTime() then
			net.Start("isawc_general")
			net.WriteString("send_maker_data")
			net.WriteEntity(weapon)
			net.WriteFloat(massMul)
			net.WriteFloat(volumeMul)
			net.WriteFloat(massConstant)
			net.WriteFloat(volumeConstant)
			net.WriteString(openSounds)
			net.WriteString(closeSounds)
			net.SendToServer()
			weapon.cooldown = RealTime() + 1
		end
	end
end