AddCSLuaFile()

ENT.Base = "gballoon_tower_base"
ENT.Type = "anim"
ENT.PrintName = "Multipurpose Engine"
ENT.Category = "#rotgb.category.tower"
ENT.Author = "Piengineer12"
ENT.Contact = "http://steamcommunity.com/id/Piengineer12/"
ENT.Purpose = "#rotgb.tower.gballoon_tower_06.purpose"
ENT.Instructions = ""
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Model = Model("models/maxofs2d/hover_propeller.mdl")
ENT.FireRate = 100
ENT.Cost = 600
ENT.AbilityCooldown = 30
ENT.LOSOffset = Vector(0,0,25)
ENT.AttackDamage = 0
ENT.DetectionRadius = 512
ENT.SeeCamo = true
ENT.InfiniteRange2 = true
ENT.rotgb_Buff = 0
ENT.UpgradeReference = {
	{
		Prices = {500,2000,7500,30000,125000,500000},
		Funcs = {
			function(self)
				self.rotgb_NoRegen = true
			end,
			function(self)
				self.rotgb_NoFast = true
			end,
			function(self)
				self.rotgb_NoHidden = true
			end,
			function(self)
				self.rotgb_NoShielded = true
			end,
			function(self)
				self.rotgb_NoImmunities = true
			end,
			function(self)
				self.HasAbility = true
			end
		}
	},
	{
		Prices = {2000,3000,19000,170000,790000,3.65e6,18e6,50e6},
		Funcs = {
			function(self)
				self.AttackDamage = self.AttackDamage + 20
			end,
			function(self)
				self.AttackDamage = self.AttackDamage + 30
			end,
			function(self)
				self.AttackDamage = self.AttackDamage + 190
			end,
			function(self)
				self.AttackDamage = self.AttackDamage + 1740
			end,
			function(self)
				self.AttackDamage = self.AttackDamage + 7940
			end,
			function(self)
				self.AttackDamage = self.AttackDamage + 36760
			end,
			function(self)
				self.AttackDamage = self.AttackDamage + 180040
			end,
			function(self)
				self.AttackDamage = self.AttackDamage + 513280
			end,
		}
	},
	{
		Prices = {400,5000,40000,100000,500e6},
		Funcs = {
			function(self)
				self.rotgb_Buff = 1
				self.FireWhenNoEnemies = true
			end,
			function(self)
				self.rotgb_Buff = 2
			end,
			function(self)
				self.rotgb_Buff = 3
			end,
			function(self)
				self.rotgb_Buff = 4
			end,
			function(self)
				self.rotgb_Buff = 5
			end
		}
	}
}
ENT.UpgradeLimits = {8,2,0}

--[[function ENT:FireFunction(gBalloons)
	if self.rotgb_Buff > 4 then
		self.rotgb_TowerCharge = (self.rotgb_TowerCharge or 0) + 1
		if self.rotgb_TowerCharge >= 60 then
			self.rotgb_TowerCharge = 0
			for k,v in pairs(ents.FindInSphere(self:GetShootPos(),self.DetectionRadius)) do
				if v:GetClass()=="gballoon_tower_base" then
					v.FireRate = v.FireRate * 1.05
					v.DetectionRadius = v.DetectionRadius * 1.05
				end
			end
		end
	end
end]]

function ENT:FireFunction(gBalloons)
	local anotherfired = 0
	local radiusTowers = {}
	for k,v in pairs(ents.FindInSphere(self:GetShootPos(),self.DetectionRadius)) do
		if self:ValidTargetIgnoreRange(v) and v:LocalToWorld(v:OBBCenter()):DistToSqr(self:GetShootPos()) <= self.DetectionRadius * self.DetectionRadius then
			if self.rotgb_NoRegen then
				v:SetBalloonProperty("BalloonRegen", false)
			end
			if self.rotgb_NoFast then
				v:SetBalloonProperty("BalloonFast", false)
			end
			if self.rotgb_NoHidden then
				v:SetBalloonProperty("BalloonHidden", false)
			end
			if self.rotgb_NoShielded then
				v:SetBalloonProperty("BalloonShielded", false)
			end
			if self.rotgb_NoImmunities then
				v:InflictRotgBStatusEffect("unimmune",999999)
			end
			if v:GetRgBE() <= self.AttackDamage/10 and self.AttackDamage > 0 then
				local pos, selfpos, dmginfo = v:GetPos(), self:GetShootPos(), DamageInfo()
				dmginfo:SetDamage(2147483647)
				dmginfo:SetBaseDamage(2147483647)
				dmginfo:SetAttacker(self:GetTowerOwner())
				dmginfo:SetInflictor(self)
				dmginfo:SetDamageForce(pos-selfpos)
				dmginfo:SetDamagePosition(pos)
				dmginfo:SetDamageType(DMG_DISSOLVE)
				dmginfo:SetReportedPosition(selfpos)
				v:TakeDamageInfo(dmginfo)
			end
		elseif v.Base=="gballoon_tower_base" then
			if self.rotgb_Buff > 0 then
				v:ApplyBuff(self, "ROTGB_TOWER_06_PASSIVE", 1, function(tower)
					tower.FireRate = tower.FireRate * 1.2
				end, function(tower)
					tower.FireRate = tower.FireRate / 1.2
				end)
			end
			if self.rotgb_Buff > 2 then
				v:ApplyBuff(self, "ROTGB_TOWER_06_PASSIVE_2", 1, function(tower)
					tower.AttackDamage = (tower.AttackDamage or 0) + 10
				end, function(tower)
					tower.AttackDamage = (tower.AttackDamage or 0) - 10
				end)
			end
			if self.rotgb_Buff > 3 then
				if v.NextFire~=v.rotgb_Tower06BuffTrack then
					v.rotgb_Tower06BuffTrack = v.NextFire
					anotherfired = math.min(anotherfired, v.FireRate or 1)
				else
					table.insert(radiusTowers, v)
				end
			end
			if self.rotgb_Buff > 4 and v ~= self then
				v:SetNWFloat("rotgb_noupgradelimit", CurTime()+2)
			end
		end
	end
	if anotherfired and next(radiusTowers) then
		local selectedTower = radiusTowers[math.random(#radiusTowers)]
		if math.random() < (selectedTower.FireRate or 1) / anotherfired then
			selectedTower:DoFireFunction()
		end
	end
end

function ENT:TriggerAbility()
	for k,v in pairs(ents.FindInSphere(self:GetShootPos(),self.DetectionRadius)) do
		if v.Base=="gballoon_tower_base" then
			v:ApplyBuff(self, "ROTGB_TOWER_06_TM", 15, function(tower)
				tower.AttackDamage = (tower.AttackDamage or 0) + 400
			end, function(tower)
				tower.AttackDamage = (tower.AttackDamage or 0) - 400
			end)
		end
	end
end

hook.Add("EntityTakeDamage","ROTGB_TOWER_06",function(ent,dmginfo)
	local caller = dmginfo:GetInflictor()
	if (IsValid(caller) and caller:GetClass()=="gballoon_base") then
		local insure = {}
		for k,v in pairs(ents.FindByClass("gballoon_tower_06")) do
			if v.rotgb_Buff > 1 then table.insert(insure, v) end
		end
		if #insure > 0 then
			local cash = dmginfo:GetDamage()*1000*player.GetCount()
			for k,v in pairs(insure) do
				v:AddCash(cash)
			end
		end
	end
end)