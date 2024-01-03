-- Enterprise Munitions Management Architecture
-- by 1337JiveTurkey
--
-- I can't tell if this is serious or not but here's an attempt at a missile
-- guidance library for From the Depths using both the object oriented and
-- coroutine functionality that was added a while back.
--
-- This differs from other Lua scripts in that it's not a complete self-contained
-- solution that does everything. It's a way to manage which missiles and targets
-- are alive with their own self-contained programs called coroutines and their
-- own object data.
--
-- The Missile and Target objects are the main objects containing the logic for
-- tracking which missiles and targets are alive. Their Update methods need to be
-- called by the main Update method but they handle everything else. When a
-- missile is launched or target is spotted, they create the appropriate objects
-- and track them until they stop existing.
--
-- MissileCoroutine and Target.CoroutineFunction are the functions that
-- tell how each missile and target will behave. Within each function, you can
-- call any of the functions defined in MissilePrototype and Target.prototype
-- with M or T in front.
--
-- Coroutine functions run until coroutine.yield() is called within the function
-- or the function exits. If the coroutine yields, it picks back up where it
-- left off at exactly the next tick. If the coroutine exits, all processing for
-- that missile or target stops. Want to keep processing? Use a loop.



-- Shared prototype giving methods for objects with positions and velocities
-- Unlike proper object oriented systems, we need to copy down all the methods
-- from this prototype provides to the child classes, MissilePrototype and
-- TargetPrototype.
Prototype = {
	-- The distance from this object to a position in space
	DistanceToPosition = function(self, otherPosition)
		return Vector3.Distance(self:Position(), otherPosition)
	end,

	-- Distance to a target or missile object
	DistanceToTarget = function(self, other)
		return Vector3.Distance(self:Position(), other:Position())
	end,

	-- Distance to a position in space
	DistanceToXYZ = function(self, x, y, z)
		return Vector3.Distance(self:Position(), Vector3(x, y, z))
	end,

	-- Either say something useful or just note that the coroutine for this target
	-- actually reached this point
	Log = function(self, text)
		if self.class.logEnabled then
			if text ~= nil then
				self.I:Log(self.ID .. ': ' .. text)
			else
				self.I:Log(self.ID .. ': Log() called')
			end
		end
	end,

	Position = function(self)
		return self.info.Position
	end,

	Velocity = function(self)
		if self.info == nil or self.info.Velocity == nil then
			return Vector3(0, 0, 0)
		end
		return self.info.Velocity
	end,

	-- Wait some number of ticks
	WaitTicks = function(self, tickCount)
		self:WaitUntilTick(self.class.tick + tickCount)
	end,

	-- Wait until the class timer hits a set amount of ticks
	WaitUntilTick = function(self, untilTick)
		self:Log('Waiting until ' .. untilTick .. ' ticks at ' .. self.class.tick .. ' ticks.')
		while untilTick > self.class.tick do
			coroutine.yield()
		end
	end,
}


-- This contains all of the methods that are available to each coroutine when it
-- runs.
MissilePrototype = {
	Detonate = function(self)
		self.I:DetonateLuaControlledMissile(self.tx,self.m)
	end,

	DistanceToPosition = Prototype.DistanceToPosition,
	DistanceToTarget = Prototype.DistanceToTarget,
	DistanceToXYZ = Prototype.DistanceToXYZ,

	-- Fly in the direction of the current velocity vector of the missile
	FlyStraight = function(self)
		self.myFlyStraight = true
		self.myTargetPosition = nil
		self.myTarget = nil
		self:KeepFlying()
	end,

	-- Fly to a position in space as a Vector3
	FlyToPosition = function(self, position)
		self.myTargetPosition = position
		self.myTarget = nil
		self.myFlyStraight = nil
		self:KeepFlying()
	end,

	-- Fly directly at a target with no lead
	FlyToTarget = function(self, target)
		self.myTarget = target
		self.myTargetPosition = nil
		self.myFlyStraight = nil
		self:KeepFlying()
	end,

	-- Flies towards a point in world space and yields
	FlyToXYZ = function(self, x, y, z)
		self:Log('Flying to ' .. x .. ', ' .. y .. ', '.. z)
		local position = Vector3(x, y, z)
		self:FlyToPosition(position)
	end,

	-- Keep flying in the direction that the last FlyTo command gave
	KeepFlying = function(self)
		if M ~= self then
			coroutine.yield("Yielded on the wrong object. self = " .. self .. " M = " .. M)
		end
		if self.myTarget ~= nil then
			local position = self.myTarget:Position()
			self.I:SetLuaControlledMissileAimPoint(self.tx, self.m, position.x, position.y, position.z)
			coroutine.yield()
		elseif self.myTargetPosition ~= nil then
			local position = self.myTargetPosition
			self.I:SetLuaControlledMissileAimPoint(self.tx, self.m, position.x, position.y, position.z)
			coroutine.yield()
		elseif self.myFlyStraight ~= nil then
			local position = self.info.Position + self.info.Velocity * 10000
			self.I:SetLuaControlledMissileAimPoint(self.tx, self.m, position.x, position.y, position.z)
			coroutine.yield()
		else
			coroutine.yield()
		end
	end,

	-- Either say something useful or just note that the coroutine for this missile
	-- actually reached this point
	Log = Prototype.Log,

	-- Testing out the ability to interact with missile parts
	LogParts = function(self)
		local missileParts = self.I:GetMissileInfo(self.tx, self.m).Parts
		for i = 1, #missileParts do
			local part = missileParts[i]
			self:Log(part.Name)
		end
	end,

	Position = Prototype.Position,

	-- Number of the missile in the currently detected salvo
	Salvo = function(self)
		return self.salvoCount
	end,

	SetThrust = function(self, newThrust)
		local missileParts = self.I:GetMissileInfo(self.tx, self.m).Parts
		for i = 1, #missileParts do
			local part = missileParts[i]
			local isVT = string.find(part.Name, "Variable thruster")
			local isTP = string.find(part.Name, "Torpedo propeller")
			if isVT or isTP then
				part:SendRegister(2, newThrust)
				return;
			end
		end
	end,

	Velocity = Prototype.Velocity,

	WaitTicks = Prototype.WaitTicks,
	WaitUntilTick = Prototype.WaitUntilTick,
}

-- This is the actual function driving each missile.
-- Instead of there being one Update() function that updates all of the missiles
-- at once, each missile has its own function called a coroutine that determines
-- how it acts. Variables in a coroutine and the state of the coroutine are all
-- independent from each other so it's possible to create variables and
-- subroutines that control a specific missile while leaving the others
-- untouched.
--
-- Since this can't have a prototype, instead of self, all the methods are bound
-- to the M namespace. This namespace exists for the duration of each coroutine
-- execution. Local variables are still local to the coroutine, so x, y, and z
-- are all variables local to each missile with no additional work required.
MissileCoroutine = function()
	-- Wait one frame for the missile to get up to speed so velocity is
	-- greater than zero.
	M:KeepFlying()

	while T ~= nil do
		local MPos = M:Position()
		local MVel = M:Velocity()
		local TPos = T:Position()
		local TVel = T:Velocity()
		local TimeToTarget = (TPos - MPos).magnitude / (MVel.magnitude + 1)

		local PredictedPos = TPos + TimeToTarget * TVel
		if TimeToTarget < 1 then
			M:SetThrust(300)
			M:FlyToTarget(T)
		elseif TimeToTarget < 5 then
			M:FlyToPosition(PredictedPos)
		else
			M:FlyToPosition(TPos + 5 * TVel)
		end
	end

	M:SetThrust(M:Salvo() * 30)
	M:FlyStraight()
end

-- Overall missile controller
-- This is the object that actually performs all of the behavior of this library
-- when MissileSystem.Update() is called. The MissileSystem scans through all
-- missiles and missile launchers and creates an instance of MissileCoroutine
-- for each missile. Each MissileCoroutine operates as its own separate function
-- controlling one missile.
MissileSystem = {
	-- This is the prototype used by every missile instance.
	prototype = MissilePrototype,
	coroutineFunction = MissileCoroutine,


	-- STUFF BELOW HERE IS FOR THE WHOLE CLASS -----------------------------------
	-- Instances indexed by their unique ID
	instances = {},

	-- Quiet logging for missiles if set to false
	logEnabled = true,

	tick = 0,

	salvoTick = 0,
	salvoCount = 0,


	-- Create a new missile.
	-- This requires ID, transceiver, missile and the missile info to work properly
	NewInstance = function(self, o)
		-- This should probably error if o is nil or missing values but Lua
		local retVal = o or {ID = 0, tx = 0, m = 0, info = {}}
		-- This metatable includes the only thing we actually care about, the prototype
		setmetatable(retVal, {__index = self.prototype})
		-- Initialize the coroutine off the shared coroutineFunction function
		if self.coroutineFunction ~= nil then
			retVal.coroutine = coroutine.create(self.coroutineFunction)
		end
		retVal.class = self
		return retVal
	end,
	
	-- Analogous to the general Update, but updates all Missiles
	Update = function(self, I)
		if self.tick == 0 and self.logEnabled then
			I:Log("Loaded Missile module")
		end
		self.tick = self.tick + 1
		self:UpdateIndex(I)
		self:UpdateInstances(I)
	end,

	-- Updates the class shared instances map so all missiles have current data.
	-- Missiles that are no longer reachable by existing APIs are discarded under
	-- the assumption that there's nothing to guide.
	UpdateIndex = function(self, I)
		-- Debugging info for when new missiles aren't showing up properly.
		local newInstances = {}
		local txs = I:GetLuaTransceiverCount()
		for tx = 0, txs - 1 do
			-- For any subsequent per-transciever operations in the future
			local txInfo = I:GetLuaTransceiverInfo(tx)
			if txInfo.Valid then
				local txName = txInfo.CustomName
				local ms = I:GetLuaControlledMissileCount(tx)
				for m = 0, ms - 1 do
					local mInfo = I:GetLuaControlledMissileInfo(tx, m)
					if mInfo.Valid then
						-- Index as string instead of number to ensure table behavior
						local mID = txName .. ':m' .. mInfo.Id
						local instance = self.instances[mID]
						if instance ~= nil then
							-- Just update data at this point
							instance.info = mInfo
							instance.tx = tx
							instance.m = m
						else
							-- Track this missile's count in any existing salvos
							if self.tick < self.salvoTick then
								self.salvoCount = self.salvoCount + 1
							else
								self.salvoCount = 0
							end
							self.salvoTick = self.tick + 20

							instance = self:NewInstance {
								ID = mID,
								info = mInfo,
								tx = tx,
								m = m,
								salvoCount = self.salvoCount
							}
						end
						newInstances[mID] = instance
					end
				end
			end
		end
		-- Replace old set of instances with new one
		self.instances = newInstances
	end,

	-- Loops through the cleaned up table and runs each missile's coroutine
	UpdateInstances = function(self, I)
		for id, missile in pairs(self.instances) do
			if missile.coroutine ~= nil then
				local status = coroutine.status(missile.coroutine)
				if status == 'suspended' then
					-- Since coroutines can't be passed self, set M with the values
					M = missile
					M.I = I
					T = TargetSystem.instance
					if T ~= nil then
						T.I = I
					end
					-- Coroutines return true if they successfully ran
					-- Second argument is whatever was passed to yield()
					-- For us, this is the error message produced if there's
					-- something that went wrong.
					local success, result = coroutine.resume(missile.coroutine)
					if result ~= nil then
						M:Log('Coroutine failed: ' .. result)
					elseif not success then
						M:Log('Coroutine failed: No error message returned by missile ' .. id)
					end
					M.I = nil
					M = nil
					if T ~= nil then
						T.I = nil
						T = nil
					end
				elseif status == 'dead' then
					-- Clear out coroutine so we don't waste time trying to execute it
					missile.coroutine = nil
				end
			end
		end
	end,
}

TargetPrototype = {
	DistanceToPosition = Prototype.DistanceToPosition,
	DistanceToTarget = Prototype.DistanceToTarget,
	DistanceToXYZ = Prototype.DistanceToXYZ,
	DoNothing = function(self)
		if T ~= self then
			coroutine.yield("Yielded on the wrong object. self = " .. self .. " T = " .. T)
		end
		coroutine.yield()
	end,

	Log = Prototype.Log,

	Position = Prototype.Position,

	Velocity = Prototype.Velocity,

	WaitTicks = Prototype.WaitTicks,
	WaitUntilTick = Prototype.WaitUntilTick,
}

-- This is the actual function computing each target
-- Since this can't have a prototype, instead of self, all the methods are bound
-- to the T namespace. This namespace exists for the duration of each coroutine
-- execution.
TargetCoroutine = function()
	T:Log('Detected target')
	while true do
		TargetSystem.instance = T
		T:DoNothing()
	end
end

-- Controller for targets tracked by the vessel
-- This is similar to the MissileSystem in that it handles 
TargetSystem = {
	prototype = TargetPrototype,
	coroutineFunction = TargetCoroutine,

	
	-- STUFF BELOW HERE IS FOR THE WHOLE CLASS -----------------------------------

	-- Instances indexed by their unique ID
	instances = {},
	instance = nil,
	
	-- Quiet logging for targets if set to false
	logEnabled = true,

	tick = 0,

	-- Create a new target.
	-- This requires ID, mainframe, target and the target info to work properly
	NewInstance = function(self, o)
		-- This should probably error if o is nil or missing values but Lua
		local retVal = o or {ID = 0, mf = 0, t = 0, info = {}}
		setmetatable(retVal, {__index = self.prototype})
		-- Initialize the coroutine off the shared coroutineFunction function
		if self.coroutineFunction ~= nil then
			retVal.coroutine = coroutine.create(self.coroutineFunction)
		end
		retVal.class = self
		return retVal
	end,

	-- Analogous to the general Update, but updates all Targets
	Update = function(self, I)
		if self.tick == 0 and self.logEnabled then
			I:Log("Loaded Target module")
		end
		self.tick = self.tick + 1
		self:UpdateIndex(I)
		self:UpdateInstances(I)
	end,

	UpdateIndex = function(self, I)
		local newInstances = {}
		local mfs = I:GetNumberOfMainframes()
		for mf = 0, mfs - 1 do
			local ts = I:GetNumberOfTargets(mf)
			for t = 0, ts - 1 do
				local tInfo = I:GetTargetInfo(mf, t)
				if tInfo.Valid then
					-- Index as string instead of number to ensure table behavior
					local tID = 't' .. tInfo.Id
					local instance = self.instances[tID]
					if instance ~= nil then
						-- Just update data at this point
						instance.info = tInfo
						instance.mf = mf
						instance.t = t
					else
						instance = self:NewInstance {
							ID = tID,
							mf = mf,
							t = t ,
							info = tInfo
						}
					end
					newInstances[tID] = instance
				end
			end
		end
		-- Replace old set of instances with new one
		self.instances = newInstances
	end,

	-- Loops through the cleaned up table and runs each target's coroutine
	UpdateInstances = function(self, I)
		for id, target in pairs(self.instances) do
			if target.coroutine ~= nil then
				local status = coroutine.status(target.coroutine)
				if status == 'suspended' then
					-- Since coroutines can't be passed self, set M with the values
					T = target
					T.I = I
					-- Coroutines return true if they successfully ran
					-- Second argument is whatever was passed to yield()
					-- For us, this is the error message produced if there's
					-- something that went wrong.
					local success, result = coroutine.resume(target.coroutine)
					if result ~= nil then
						T:Log('Coroutine failed: ' .. result)
					elseif not success then
						T:Log('Coroutine failed: No error message returned by misssile ' .. id)
					end
					T.I = nil
					T = nil
				elseif status == 'dead' then
					-- Clear out coroutine so we don't waste time trying to execute it
					target.coroutine = nil
				end
			end
		end
	end,
}

-- Update function for all the individual update functions
function Update(I)
	TargetSystem:Update(I)
	MissileSystem:Update(I)
end
