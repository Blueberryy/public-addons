AddCSLuaFile()

ENT.Base = "gballoon_tower_base"
ENT.Type = "anim"
ENT.PrintName = "Gatling Gun Knight"
ENT.Category = "#rotgb.category.tower"
ENT.Author = "Piengineer12"
ENT.Contact = "http://steamcommunity.com/id/Piengineer12/"
ENT.Purpose = "#rotgb.tower.gballoon_tower_04.purpose"
ENT.Instructions = ""
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Model = Model("models/props_phx/games/chess/black_knight.mdl")
ENT.FireRate = 10
ENT.Cost = 550
ENT.DetectionRadius = 256
ENT.UseLOS = true
ENT.LOSOffset = Vector(0,0,40)
ENT.UserTargeting = true
ENT.AttackDamage = 10
ENT.IsChessPiece = true
ENT.rotgb_Spread = 60
ENT.rotgb_Shots = 1
ENT.rotgb_LaserDamageMul = 50
ENT.UpgradeReference = {
	{
		Names = {"Stabilized Barrel","Consistent Barrel Spinner","Computerized Targeting","Laser Shooter","Ray of Doom","G.R.E.E.N. Beams"},
		Descs = {
			"Slightly reduces bullet spread.",
			"Considerably reduces bullet spread.",
			"Deals considerably increased damage versus gBlimps. Also enables the tower to see hidden gBalloons.",
			"Fires a continuous, perfectly accurate focused laser that shreds gBalloons. However, the tower no longer pops Purple gBalloons.",
			"Fires an even bigger beam that obliterates all gBalloons in its path, regardless of immunities.",
			"BLARGGGH!!!"
		},
		Prices = {250,750,5000,50000,400000,25e6},
		Funcs = {
			function(self)
				self.rotgb_Spread = self.rotgb_Spread / 1.5
			end,
			function(self)
				self.rotgb_Spread = self.rotgb_Spread / 2
			end,
			function(self)
				self.rotgb_ExtraVsCeramic = true
				self.SeeCamo = true
			end,
			function(self)
				self.FireRate = self.FireRate * 3
				self.rotgb_UseLaser = 1
			end,
			function(self)
				self.rotgb_LaserDamageMul = self.rotgb_LaserDamageMul / 2
				self.rotgb_UseLaser = 2
			end,
			function(self)
				self.UserTargeting = false
				self.rotgb_LaserDamageMul = self.rotgb_LaserDamageMul * 10
			end
		}
	},
	{
		Names = {"Higher Torque","Bigger Bullets","TripShot","Super High Torque","DodecaShot","A Million Rounds Per Minute"},
		Descs = {
			"Slightly increases fire rate.",
			"Slightly increases range and considerably increases damage dealt by each bullet.",
			"Fires three bullets per shot.",
			"Considerably increases fire rate.",
			"Slightly increases bullet spread, but twelve bullets are fired per shot!",
			"Considerably increases bullet spread, but tremendously increases damage dealt by each bullet and sixty bullets are fired per shot!"
		},
		Prices = {250,1250,4000,6000,17500,175000},
		Funcs = {
			function(self)
				self.FireRate = self.FireRate * 1.5
			end,
			function(self)
				self.DetectionRadius = self.DetectionRadius * 1.5
				self.AttackDamage = self.AttackDamage + 10
			end,
			function(self)
				self.rotgb_Shots = self.rotgb_Shots * 3
			end,
			function(self)
				self.FireRate = self.FireRate * 2
			end,
			function(self)
				self.rotgb_Spread = self.rotgb_Spread * 1.5
				self.rotgb_Shots = self.rotgb_Shots * 4
			end,
			function(self)
				self.rotgb_Spread = self.rotgb_Spread * 2
				self.rotgb_Shots = self.rotgb_Shots * 5
				self.AttackDamage = self.AttackDamage + 40
			end
		}
	}
}
ENT.UpgradeLimits = {6,2}

function ENT:ROTGB_ApplyPerks()
	self.rotgb_Spread = self.rotgb_Spread * (1+hook.Run("GetSkillAmount", "gatlingGunKnightSpread")/100)
end

local function SnipeEntity()
	while true do
		local self,ent = coroutine.yield()
		local startPos = self:GetShootPos()
		--uDir:Normalize()
		if self.rotgb_UseLaser then
			local laser = ents.Create(self.rotgb_UseLaser==1 and "env_laser" or "env_beam")
			local startEnt = self.rotgb_UseLaser==2 and ents.Create("info_target") or NULL
			--local endEnt = ents.Create("info_target")
			laser:SetPos(startPos)
			--[[if IsValid(endEnt) then
				endEnt:SetName("ROTGB04_"..endEnt:GetCreationID())
				endEnt:SetPos(ent:GetPos()+ent.loco:GetVelocity()*0.1+ent:OBBCenter())
			end]]
			local oldEntName = ent:GetName()
			local entityName = ent:GetName() ~= "" and ent:GetName() or "ROTGB04_2_"..self:GetCreationID()
			ent:SetName(entityName)
			if IsValid(startEnt) then
				startEnt:SetName("ROTGB04_"..self:GetCreationID())
				startEnt:SetPos(startPos)
				startEnt:Spawn()
			end
			laser:SetKeyValue("LaserTarget",entityName)
			laser:SetKeyValue("renderamt","255")
			laser:SetKeyValue("rendercolor",self.rotgb_UseLaser==1 and "0 255 127" or self.rotgb_LaserDamageMul > 200 and "0 255 0" or "255 0 0")
			laser:SetKeyValue("width","3")
			laser:SetKeyValue("BoltWidth",math.sqrt(self.rotgb_LaserDamageMul))
			laser:SetKeyValue("NoiseAmplitude","0")
			laser:SetKeyValue("texture","sprites/laserbeam.spr")
			laser:SetKeyValue("TextureScroll","35")
			laser:SetKeyValue("damage",self.AttackDamage*self.rotgb_LaserDamageMul*self.rotgb_Shots)
			laser:SetKeyValue("LightningStart","ROTGB04_"..self:GetCreationID())
			laser:SetKeyValue("LightningEnd",entityName)
			laser:SetKeyValue("HDRColorScale","1")
			laser:SetKeyValue("spawnflags","33")
			laser:SetKeyValue("life",0.2)
			laser:Spawn()
			laser:Activate()
			laser.rotgb_Owner = self
			laser.rotgb_UseLaser = self.rotgb_UseLaser
			laser:Fire("TurnOn")
			timer.Simple(0.2,function()
				if IsValid(laser) then
					laser:Remove()
				end
				if (IsValid(ent) and entityName == ent:GetName()) then
					ent:SetName(oldEntName)
				end
				if IsValid(startEnt) then
					startEnt:Remove()
				end
				--[[if IsValid(endEnt) then
					endEnt:Remove()
				end]]
			end)
		else
			local uDir = ent:LocalToWorld(ent:OBBCenter())-startPos
			local bullet = {
				Attacker = self:GetTowerOwner(),
				Callback = function(attacker,tracer,dmginfo)
					dmginfo:SetDamageType(self.rotgb_CanPopGray and DMG_SNIPER or DMG_BULLET)
				end,
				Damage = self.rotgb_ExtraVsCeramic and ent:GetBalloonProperty("BalloonBlimp") and self.AttackDamage*2 or self.AttackDamage,
				Distance = self.DetectionRadius*1.5,
				HullSize = 1,
				Num = self.rotgb_Shots,
				Tracer = math.floor(2*math.sqrt(self.rotgb_Shots)),
				AmmoType = "SniperRound",
				TracerName = "Tracer",
				Dir = uDir,
				Spread = Vector(self.rotgb_Spread,self.rotgb_Spread,0),
				Src = startPos
			}
			self:FireBullets(bullet)
		end
	end
end

ENT.thread = coroutine.create(SnipeEntity)
coroutine.resume(ENT.thread)

function ENT:FireFunction(gBalloons)
	if self.UserTargeting then
		local perf,str = coroutine.resume(self.thread,self,gBalloons[1])
		if not perf then error(str) end
	else
		--local i = 1
		for k,v in pairs(gBalloons) do
			local perf,str = coroutine.resume(self.thread,self,v)
			if not perf then error(str) end
			--i = i + 1
			--if i > 10 then break end
		end
	end
end