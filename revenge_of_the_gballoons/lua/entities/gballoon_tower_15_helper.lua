AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.Type = "nextbot"

function ENT:Initialize()
	self:SetModel("models/maxofs2d/motion_sensor.mdl")
	self.NextFire = CurTime()
	self.CreationTime = self:GetCreationTime()
	self.rotgb_IgnoreCollisions = true
	self:SetHealth(1e9)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	if SERVER then
		self:SetBloodColor(DONT_BLEED)
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Entity",0,"SpawnedTower")
	self:NetworkVar("Entity",1,"Enemy")
end

function ENT:DetectionRadius()
	return self:GetSpawnedTower().rotgb_TurretRange or 0
end

function ENT:AttackDamage()
	return self:GetSpawnedTower().AttackDamage
end

function ENT:GetShootPos()
	return self:GetPos() + self:OBBCenter()
end

function ENT:OnInjured(dmginfo)
	dmginfo:SetDamage(0)
	return true
end

function ENT:HaveEnemy()
	local tower = self:GetSpawnedTower()
	return IsValid(tower) and not tower:IsStunned() and (tower:ValidTargetIgnoreRange(self:GetEnemy()) or self:FindEnemy())
end

function ENT:FindEnemy()
	if not IsValid(self:GetSpawnedTower()) then return false end
	self.balloonTable = self.balloonTable or {}
	self.lastBalloonTrace = self.lastBalloonTrace or {}
	table.Empty(self.balloonTable)
	local selfpos = self:GetShootPos()
	self.gBTraceData = self.gBTraceData or {
		filter = self,
		mask = MASK_SHOT,
		output = self.lastBalloonTrace
	}
	self.gBTraceData.start = selfpos
	for k,v in pairs(ROTGB_GetBalloons()) do
		if self:GetSpawnedTower():ValidTargetIgnoreRange(v) then
			self.gBTraceData.endpos = v:GetPos()+v:OBBCenter()
			util.TraceLine(self.gBTraceData)
			if self.lastBalloonTrace.Entity == v then
				local mode = self:GetSpawnedTower():GetTargeting()
				if mode==0 then
					self.balloonTable[v] = v:GetDistanceTravelled()
				elseif mode==1 then
					self.balloonTable[v] = -v:GetDistanceTravelled()
				elseif mode==2 then
					self.balloonTable[v] = v:GetRgBE()
				elseif mode==3 then
					self.balloonTable[v] = -v:GetRgBE()
				elseif mode==4 then
					self.balloonTable[v] = v:BoundingRadius()^2/self:GetRangeSquaredTo(v)
				elseif mode==5 then
					self.balloonTable[v] = -v:BoundingRadius()^2/self:GetRangeSquaredTo(v)
				elseif mode==6 then
					self.balloonTable[v] = v.loco:GetAcceleration()
				elseif mode==7 then
					self.balloonTable[v] = -v.loco:GetAcceleration()
				end
			end
		end
	end
	if next(self.balloonTable) then
		self:SetEnemy(table.GetWinningKey(self.balloonTable))
		return true
	else return false
	end
end

function ENT:FireAtEnemy()
	if (self.NextFire or 0) < CurTime() then
		self.NextFire = CurTime() + 1/self:GetSpawnedTower().FireRate/(self:GetSpawnedTower().BonusFireRate or 1)/(CurTime() > self.CreationTime+19 and self:GetSpawnedTower().rotgb_PostFireRate or 1)
		local iscrit = math.random() < self:GetSpawnedTower().rotgb_CritChance
		local damage = self:AttackDamage()
		if iscrit then
			damage = damage * self:GetSpawnedTower().rotgb_CritMul
		end
		if CurTime() > self.CreationTime+19 then
			damage = damage * self:GetSpawnedTower().rotgb_PostMul
		end
		if self:GetSpawnedTower().rotgb_TurretLasers then
			damage = damage*5
			local targets = {self:GetEnemy()}
			if self:GetSpawnedTower().rotgb_TurretMultihit then
				table.Empty(targets)
				local selfpos = self:GetShootPos()
				self.gBTraceData.start = selfpos
				for k,v in pairs(ents.FindInSphere(selfpos,self:DetectionRadius())) do
					if (v:GetClass()=="gballoon_base" and (not v:GetBalloonProperty("BalloonHidden") or self:GetSpawnedTower().SeeCamo)) then
						self.gBTraceData.endpos = v:GetPos()+v:OBBCenter()
						util.TraceLine(self.gBTraceData)
						if self.lastBalloonTrace.Entity == v then
							table.insert(targets, v)
						end
					end
				end
			end
			for k,v in pairs(targets) do
				if self:GetSpawnedTower().rotgb_TurretBucks then
					self:GetSpawnedTower():AddCash(20, self:GetSpawnedTower():GetTowerOwner())
				end
				if iscrit then
					--util.ScreenShake(self:GetShootPos(), 4, 20, 0.5, 1024)
					v:ShowCritEffect()
					--self:EmitSound("phx/epicmetal_hard"..math.random(7)..".wav",75,100,1,CHAN_WEAPON)
				end
				local laser = ents.Create("env_laser")
				laser:SetPos(self:GetShootPos())
				local oldEntName = v:GetName()
				local entityName = v:GetName() ~= "" and v:GetName() or "laser_target"..v:GetCreationID()
				v:SetName(entityName)
				laser:SetKeyValue("LaserTarget",entityName)
				laser:SetKeyValue("renderamt","255")
				laser:SetKeyValue("rendercolor",iscrit and "255 0 255" or "0 0 255")
				laser:SetKeyValue("width","4")
				laser:SetKeyValue("BoltWidth","4")
				laser:SetKeyValue("NoiseAmplitude","0")
				laser:SetKeyValue("texture","sprites/laserbeam.spr")
				laser:SetKeyValue("TextureScroll","35")
				laser:SetKeyValue("damage",damage --[[* (v:GetBalloonProperty("BalloonBlimp") and self:GetSpawnedTower().rotgb_CritMulBlimp or 1)]] )
				laser:SetKeyValue("LightningEnd",entityName)
				laser:SetKeyValue("HDRColorScale","1")
				laser:SetKeyValue("spawnflags","33")
				laser:SetKeyValue("life",1/self:GetSpawnedTower().FireRate)
				laser:Spawn()
				laser:Activate()
				laser.rotgb_Owner = self:GetSpawnedTower()
				laser.rotgb_UseLaser = iscrit and 2 or 1
				laser:Fire("TurnOn")
				timer.Simple(1/9,function()
					if IsValid(laser) then
						laser:Remove()
					end
					if (IsValid(v) and entityName == v:GetName()) then
						v:SetName(oldEntName)
					end
				end)
			end
		else
			self.rotgb_Owner = self:GetSpawnedTower()
			if self.rotgb_Owner.rotgb_TurretBucks then
				self.rotgb_Owner:AddCash(20)
			end
			local enemy = self:GetEnemy()
			local dir = enemy:GetPos()
			self.loco:FaceTowards(dir)
			dir:Add(enemy:OBBCenter())
			dir:Sub(self:GetShootPos())
			dir:Normalize()
			if iscrit then
				--[[if enemy:GetBalloonProperty("BalloonBlimp") then
					damage = damage * self:GetSpawnedTower().rotgb_CritMulBlimp
				end]]
				enemy:ShowCritEffect()
			end
			if self.rotgb_Owner.rotgb_Slowdown and enemy:GetRgBE() <= enemy:GetRgBEByType("gballoon_blimp_green") then
				enemy:Slowdown("ROTGB_TOWER_15",0.25,1)
			end
			local bulletstruct = {
				Attacker = self.rotgb_Owner:GetTowerOwner(),
				Damage = damage,
				Force = damage,
				Distance = self:DetectionRadius(),
				HullSize = 64,
				Num = 1,
				Tracer = 1,
				AmmoType = "Pistol",
				TracerName = "Tracer",
				Dir = dir,
				Spread = vector_origin,
				Src = self:GetShootPos(),
				IgnoreEntity = self
			}
			bulletstruct.Callback = function(atkself,trace,dmginfo)
				local effdata = EffectData()
				effdata:SetEntity(self)
				effdata:SetOrigin(self:GetShootPos())
				util.Effect("ShellEject",effdata,true,true)
				self:EmitSound("weapons/pistol/pistol_fire2.wav",60,100,1,CHAN_WEAPON)
				if iscrit then
					dmginfo:SetDamageType(DMG_GENERIC)
					--util.ScreenShake(self:GetShootPos(), 4, 20, 0.5, 1024)
				end
			end
			self:FireBullets(bulletstruct)
		end
	end
end

function ENT:Think()
	if SERVER then
		if IsValid(self:GetSpawnedTower()) then
			self.loco:SetDesiredSpeed(self:GetSpawnedTower().rotgb_TurretSpeed)
			self.loco:SetAcceleration(self:GetSpawnedTower().rotgb_TurretSpeed*5)
			self.loco:SetDeceleration(self:GetSpawnedTower().rotgb_TurretSpeed*5)
			if CurTime() > self.CreationTime+20 then
				self:Remove()
			elseif CurTime() > self.CreationTime+19 then
				local effdata = EffectData()
				effdata:SetEntity(self)
				effdata:SetOrigin(self:GetShootPos())
				effdata:SetMagnitude(1)
				effdata:SetScale(0)
				effdata:SetRadius(4)
				util.Effect("Sparks", effdata)
			end
		else
			self:Remove()
		end
	end
end

function ENT:MoveToEnemy()
	local enemy = self:GetEnemy()
	local path = Path("Chase")
	path:SetMinLookAheadDistance(64)
	path:SetGoalTolerance(self:DetectionRadius()/8)
	path:Compute(self, enemy:GetPos())
	while IsValid(path) and self:HaveEnemy() do
		if self:GetEnemy() ~= enemy then break end
		if path:GetAge() > 1 then
			path:Compute(self, enemy:GetPos())
		end
		path:Chase(self, enemy)
		if self.loco:IsStuck() then
			if (self.ResetStuck or 0) < CurTime() then
				self.UnstuckAttempts = 0
			end
			self.UnstuckAttempts = self.UnstuckAttempts + 1
			self.ResetStuck = CurTime() + 10
			if self.UnstuckAttempts == 1 then -- A simple jump should fix it.
				self.loco:Jump()
				path:Compute(self, enemy:GetPos())
				self.loco:ClearStuck()
			elseif self.UnstuckAttempts == 2 then -- That didn't fix it, try to teleport slightly upwards instead.
				self:SetPos(self:GetPos()+vector_up*20)
				self.loco:ClearStuck()
			elseif self.UnstuckAttempts == 3 then -- If not, ask GMod kindly to free us.
				self:HandleStuck()
			else -- If not, just teleport us ahead on the path. (Sanic method)
				self:SetPos(path:GetPositionOnPath(path:GetCursorPosition()+2^self.UnstuckAttempts))
				self.loco:ClearStuck()
			end
		end
		coroutine.yield()
	end
end

function ENT:RunBehaviour()
	while IsValid(self:GetSpawnedTower()) do
		if self:HaveEnemy() and not GetConVar("ai_disabled"):GetBool() then
			local result = self:MoveToEnemy()
			if not IsValid(self:GetSpawnedTower()) then
				self:Remove()
			elseif self:HaveEnemy() and not GetConVar("ai_disabled"):GetBool() then
				while (self:HaveEnemy() and self:GetRangeSquaredTo(self:GetEnemy()) <= self:DetectionRadius()^2) do
					self:FireAtEnemy()
					coroutine.yield()
				end
			--[[else
				self:LogError(tostring(result),"pathfinding")
				coroutine.wait(0.5)]]
			end
		else
			self.loco:SetDesiredSpeed(0)
			coroutine.wait(0.1)
		end
	end
	self:Remove()
end

function ENT:PreEntityCopy()
	self.rotgb_DuplicatorTimeOffset = CurTime()
end

function ENT:PostEntityPaste(ply,ent,tab)
	self:AddTimePhase(CurTime() - (self.rotgb_DuplicatorTimeOffset or CurTime()))
end

function ENT:AddTimePhase(timeToAdd)
	self.NextFire = (self.NextFire or 0) + timeToAdd
	self.CreationTime = (self.CreationTime or 0) + timeToAdd
	self.ResetStuck = (self.ResetStuck or 0) + timeToAdd
end