-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
---Enumerations for Logging purposes
ERROR = 0
WARNING = 1
SYSTEM = 2
LISTS = 3
VECTORS = 4
--This could be changed to something like: https://stefano-m.github.io/lua-enum/
--But should suffice for here
DebugLevel = SYSTEM -- 0|ERROR  5|WARNING  10|SYSTEM  100|LISTS  200|VECTORS
--LISTS: length of lists
-- I marked lines where I need to add more code. with "#EDITHERE"
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

--------------
-- Settings --
--------------

-- chapters --
-- 1. guidance groups
-- 2. missile behaviours
-- 3. prediction guidance


-- guidance groups --
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- I have already created 5 different guidance groups.
-- You can give luanchers one of the names from "LaunchpadName" 
-- and they will be controlled by the Ai named like the "ControllingAiName" says
-- and they will behave like "MissileBehaviourName" says.
-- You can remove or add groups.
-- You can change the settings of a group, which are:
-- 1. LaunchpadName, 2. ControllingAiName, 3. MissileBehaviourName

--                      LaunchpadName     ControllingAiName    MissileBehaviourName
GuidanceGroups =  { {"missiles 01",   "missile ai 01",     "Diving01"},
                    {"missiles 02",   "missile ai 02",     "Diving01"},
                    {"missiles 03",   "missile ai 03",     "Diving01"},
                    {"missiles 04",   "missile ai 04",     "Diving01"},
                    {"missiles 05",   "missile ai 01",     "Orbit01"}
                    }



-- missile behaviours --
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-- Here you can define different behaviours for missiles.
-- You can then tell a missile group, what behaviour to use.
-- To do so, just match "FlightBehaviourName" and "MissileBehaviourName" and
-- the GuiadanceGroup will know what MissileBehaviour to use

-- There are multiple BehaviourPattern to choose from. They each require different settings.
-- Here is a list of behaviours I implemented:

-- 1.
-- BehaviourPatternName: "Diving"
-- This BehaviourPattern has 3 options:
-- 1. FlightBehaviourName: A GuiadanceGroup with this MissileBehaviourName will use this BehaviourPattern.
-- 2. CruisingAltitude: The cruising altitude the missile will stay at, bevore diving on the enemy
-- 3. DivingRadius: The distance to the enemy (no respect to altitude difference) below which we dive.

-- 2.
-- BehaviourPatternName: "Bombing"
-- This BehaviourPattern has 3 options:
-- 1. FlightBehaviourName: A GuiadanceGroup with this MissileBehaviourName will use this BehaviourPattern.
-- 2. AimPointUpShift: We aim above the actual aimpoint, to drop the bomb on top of the enemie.
-- 3. DivingRadius: Thats the distance below we stop aiming above the actual aimpoint and try to strike.

--3.
-- BehaviourPatternName: "CustomCurve"
-- not done yet

--4.
-- BehaviourPatternName: "Orbit"
-- This BehaviourPattern has 6 options:
-- 1. Radius: the radius if the orbit
-- 2. HightOffset: relative altitude to the target
-- 3. MaxHight: highest allowed altitude
-- 4. MinHight: lowest allowed altitude
-- 5. WhiggleRadius: additional rotation to irretate enemy counter measurements
-- 6. T: time for one rotation of the whiggle motion

--                  BehaviourPattern    FlightBehaviourName   CruisingAltitude   DivingRadius     (#unfinished)
MissileBehaviours = { {"Diving",       "Diving01",          200,               500         }, -- flies on CruisingAltitude till being within DivingRadius, when it strickes down on enemy

--                  BehaviourPattern    FlightBehaviourName   AimPointUpShift    DivingRadius
                      {"Bombing",      "Bombing01",         30,                20          },

--                  BehaviourPattern    FlightBehaviourName     Radius      HightOffset     MaxHight    MinHight    WhiggleRadius   T
                      {"Orbit",        "Orbit01",               200,        50,             600,        15,         5,              2}
                    }



-- prediction guidance --
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-- not done yet but available




-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- here comes my code --
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- This function is called each game tick by the game engine
-- The object named "I" contains a bunch of data related to the game
function Update(I)
    GeneralGuidance(I)
end



-- This is the main function organising my functions
function GeneralGuidance(I)
    if GeneralGuidanceInitDone ~= true then
        GeneralGuidanceInit(I)
    else
        GeneralGuidanceUpdate(I)
    end
end



-- This is what controls the launchpads
function GeneralGuidanceUpdate(I)
    -- iterates GuidanceGroups
    for GuidanceGroupId, GuidanceGroupData in pairs(GuidanceGroups) do
        if GuidanceGroupData.Valid then
            local MissileBehaviour = MissileBehaviours[GuidanceGroupData.MissileBehaviourId]
            local TargetInfo = I:GetTargetInfo(GuidanceGroupData.MainframeId, 0)
            local AimPointPosition = TargetInfo.AimPointPosition
            local BehaviourPattern = MissileBehaviour[1]
            local GameTime = I:GetGameTime()

            -- iterates launchpads
            for key, luaTransceiverIndex in pairs(GuidanceGroupData.luaTransceiverIndexes) do
                -- iterates missiles
                for missileIndex=0 , I:GetLuaControlledMissileCount(luaTransceiverIndex)-1 do
                    local PredictedAimPointPosition = MissilePredictionGuiadance(TargetInfo,I:GetLuaControlledMissileInfo(luaTransceiverIndex,missileIndex),AimPointPosition,GameTime,1,20,I)
                    local matched = false
                    if MissileData[luaTransceiverIndex] == nil then MissileData[luaTransceiverIndex] = {} end
                    if MissileData[luaTransceiverIndex][missileIndex] == nil then MissileData[luaTransceiverIndex][missileIndex] = {} end

                    -- here the correct MissileControl function is selected
                    if      BehaviourPattern == "Diving"        then MissileControlDiving(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPointPosition); matched = true
                    elseif  BehaviourPattern == "CustomCurve"   then MissileControlCustomCurve(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPointPosition); matched = true
                    elseif  BehaviourPattern == "Bombing"       then MissileControlBomb(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPointPosition); matched = true
                    elseif  BehaviourPattern == "Orbit"       then MissileControlOrbit(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPointPosition); matched = true
                    end
                    -- more behaviours to come #EDITHERE

                    if not matched then MyLog(I,WARNING,"WARNING:  GuidanceGroup with LaunchpadName ".. GuidanceGroupData[1].. " has no working MissileBehaviour!") end
                end
            end
        end
    end
    ClearMissileDataPG(GameTime)
end



-- creates lists of all the launchpads Ids so addressing them is optimised
-- finds Ids of controlling ai mainframes
-- finds Id of MissileBehaviour
function GeneralGuidanceInit(I)
    I:ClearLogs()
    MyLog(I,SYSTEM,"Running GeneralGuidanceInit")
    GeneralGuidanceInitDone = false
    local ErrorDetected = false

    -- a list containing a set of data for each missile
    MissileData = {}

    -- iterates GuidanceGroups
    local LuaTransceiverCount = I:GetLuaTransceiverCount()
    for GuidanceGroupId, GuidanceGroupData in pairs(GuidanceGroups) do
        local LaunchpadName = GuidanceGroupData[1]
        local ControllingAiName = GuidanceGroupData[2]
        local MissileBehaviourName = GuidanceGroupData[3]

        local GuidanceGroupIsSetUpCorrect = true

        -- finds all the launchpads Ids
        local LaunchpadIds = {}
        for luaTransceiverIndex=0 , LuaTransceiverCount-1 do
            local LuaTransceiverInfo = I:GetLuaTransceiverInfo(luaTransceiverIndex)
            if LuaTransceiverInfo.CustomName == LaunchpadName then
                table.insert(LaunchpadIds,luaTransceiverIndex)
            end
        end
        GuidanceGroups[GuidanceGroupId].luaTransceiverIndexes = LaunchpadIds
        if #LaunchpadIds == 0 then MyLog(I,WARNING,"WARNING:  GuidanceGroup with LaunchpadName "..LaunchpadName.. " has no assigned launchpads!"); GuidanceGroupIsSetUpCorrect = false end

        -- iterating ai mainframes
        for index=0 ,I:Component_GetCount(26)-1 do -------------------------------------------------------------------------------------------------- not sure about indexing
            if I:Component_GetBlockInfo(26,index).CustomName == ControllingAiName then
                GuidanceGroups[GuidanceGroupId].MainframeId = index
            end
        end
        if GuidanceGroups[GuidanceGroupId].MainframeId == nil then MyLog(I,WARNING,"WARNING:  GuiadanceGroup with LaunchpadName "..LaunchpadName.. " has no assigned ai mainframe!"); GuidanceGroupIsSetUpCorrect = false end

        -- iterating MissileBehaviours
        for MissileBehaviourId, MissileBehaviour in pairs(MissileBehaviours) do
            -- checks if the MissileGuidance group can find a MissileBehaviour
            if MissileBehaviourName == MissileBehaviour[2] then
                GuidanceGroups[GuidanceGroupId].MissileBehaviourId = MissileBehaviourId
            end
        end
        if GuidanceGroups[GuidanceGroupId].MissileBehaviourId == nil then MyLog(I,WARNING,"WARNING:  GuiadanceGroup with LaunchpadName "..LaunchpadName.. " has no configurated MissileBehaviour!"); GuidanceGroupIsSetUpCorrect = false end
        

        GuidanceGroups[GuidanceGroupId].Valid = GuidanceGroupIsSetUpCorrect
    end

    if ErrorDetected == false then
        GeneralGuidanceInitDone = true
    else
        MyLog(I,SYSTEM,"GeneralGuidanceInit failed")
    end
end



-- guides missiles along waypoints
-- lti = luaTransceiverIndex | mi = missileIndex
function MissileControlDiving(I,lti,mi,MissileBehaviour,AimPointPosition)


    local MissileInfo = I:GetLuaControlledMissileInfo(lti,mi)
    local CruisingAltitude = MissileBehaviour[3]
    local DivingRadius = MissileBehaviour[4]

    local TimeSinceLaunch = MissileInfo.TimeSinceLaunch
    local Position = MissileInfo.Position

    -- resets MissileData for a new missile
    if TimeSinceLaunch < 0.1 then
        MissileData[lti][mi] = {}
    else
        if Position.y > CruisingAltitude then
            MissileData[lti][mi].Waypoint01 = true -- vertical launch done
        end

        if (AimPointPosition - Vector3(Position.x,AimPointPosition.y,Position.z)).magnitude < DivingRadius then
            MissileData[lti][mi].Waypoint02 = true -- cruising done
        end

        if MissileData[lti][mi].Waypoint01 ~= true then
            aimPoint = Position + Vector3(0,10,0)

        elseif MissileData[lti][mi].Waypoint02 ~= true then
            aimPoint = Vector3  (AimPointPosition.x,CruisingAltitude,AimPointPosition.z)
        else
            aimPoint = AimPointPosition
        end
        I:SetLuaControlledMissileAimPoint(lti,mi,aimPoint.x,aimPoint.y,aimPoint.z)
    end
end


-- #EDITHERE
-- not done yet
function MissileControlCustomCurve(I,lti,mi,MissileBehaviour,AimPointPosition)
    local MissileInfo = I:GetLuaControlledMissileInfo(lti,mi)
    local TimeSinceLaunch = MissileInfo.TimeSinceLaunch
    local Position = MissileInfo.Position

    local m_apt_Vector = AimPointPosition - Position
    local m_apt_Distance = m_apt_Vector.magnitude
    local m_apt_PlaneVector = Vector3(AimPointPosition.x,0,AimPointPosition.z) - Vector3(Position.x,0,Position.z)
    local m_apt_PlaneDistance = m_apt_PlaneVector.magnitude
    local m_apt_Elevation = math.acos(m_apt_PlaneDistance / m_apt_Distance)


    -- resets MissileData for a new missile
    if TimeSinceLaunch < 0.1 then
        MissileData[lti][mi] = {}
        MissileData[lti][mi].LaunchPosition = Position
        MissileData[lti][mi].m_apt_InitialPlaneDistance = m_apt_PlaneDistance
    else
        local x = MissileData[lti][mi].m_apt_InitialPlaneDistance /2
        local height = AimPointPosition.y + 0
    end
end



-- lets missiles with no propulsion glide onto the enemie
-- lti = luaTransceiverIndex | mi = missileIndex
function MissileControlBomb(I,lti,mi,MissileBehaviour,AimPointPosition)
    local MissileInfo = I:GetLuaControlledMissileInfo(lti,mi)
    local TimeSinceLaunch = MissileInfo.TimeSinceLaunch
    local Position = MissileInfo.Position

    local SettingA = 0.8 -- not to sure about this setting yet
    local DivingRadius = MissileBehaviour[4]
    local AimPointUpShift = Vector3(0,MissileBehaviour[3],0)

    local aimPoint = AimPointPosition + AimPointUpShift
    local m_apt_Vector = AimPointPosition - Position
    local ClosingVelocityXZ

    local m_apt_PlaneVector = Vector3(AimPointPosition.x,0,AimPointPosition.z) - Vector3(Position.x,0,Position.z)
    local alpha = -math.atan2(m_apt_Vector.y,m_apt_PlaneVector.magnitude)
    if m_apt_PlaneVector.magnitude < DivingRadius then
        aimPoint = AimPointPosition
    -- if we are already above the enemy, we can just dive 
    elseif alpha > math.pi/3 then -- == 60 degrees 
        aimPoint = AimPointPosition + AimPointUpShift
    else
        -- making sure that MissileData is initialized
        -- calculates at what rate we are getting closer to the enemie, so we can adjust the diving angle
        if MissileData[lti] ~= nil then
            if MissileData[lti][mi] ~= nil then
                if MissileData[lti][mi].m_apt_VectorLast ~= nil then
                    --ClosingVelocity = (m_apt_Vector - MissileData[lti][mi].m_apt_VectorLast) / (TimeSinceLaunch - MissileData[lti][mi].TimeSinceLaunchLast)
                    local VectorA = Vector3(m_apt_Vector.x,0,(m_apt_Vector.z))
                     VectorB = Vector3(MissileData[lti][mi].m_apt_VectorLast.x,0,MissileData[lti][mi].m_apt_VectorLast.z)
                    ClosingVelocityXZ = (VectorA - VectorB) / (TimeSinceLaunch - MissileData[lti][mi].TimeSinceLaunchLast)

                    -- if we fall faster than we get closer in XZ, we miss the target, so we slow the falling rate by aiming up
                    if math.abs(MissileInfo.Velocity.y) > ClosingVelocityXZ.magnitude * SettingA then
                        aimPoint = Vector3(AimPointPosition.x,MissileInfo.Position.y + m_apt_PlaneVector.magnitude,AimPointPosition.z)
                    end
                end
            end
        end
    end
    -- resets MissileData for a new missile
    if TimeSinceLaunch < 0.1 then
        MissileData[lti][mi] = {}
    else
        MissileData[lti][mi].m_apt_VectorLast = m_apt_Vector
        MissileData[lti][mi].TimeSinceLaunchLast = TimeSinceLaunch
    end

    I:SetLuaControlledMissileAimPoint(lti,mi,aimPoint.x,aimPoint.y,aimPoint.z)
end


-- lets missliles orbit around the AimPointPosition
function MissileControlOrbit(I,lti,mi,MissileBehaviour,AimPointPosition)
    local Radius = MissileBehaviour[3]
    local HightOffset = MissileBehaviour[4]
    local MaxHight = MissileBehaviour[5]
    local MinHight = MissileBehaviour[6]
    local WhiggleRadius = MissileBehaviour[7]
    local T = MissileBehaviour[8]
    local MissileInfo = I:GetLuaControlledMissileInfo(lti,mi)
    local Position = MissileInfo.Position
    local alpha = math.atan2(AimPointPosition.x - Position.x, AimPointPosition.z - Position.z) * 180/math.pi + 10
    local r =  Quaternion.AngleAxis(alpha, Vector3.up) * -Vector3.forward

    local WhiggleAxis = Vector3(-r.z,0,r.x).normalized
    local Whiggle = Quaternion.AngleAxis(I:GetTime() * 360 / T, WhiggleAxis) * Vector3.up * WhiggleRadius

    local aimPoint = AimPointPosition + r * Radius + Vector3(0,HightOffset,0) + Whiggle
    if aimPoint.y > MaxHight then aimPoint.y = MaxHight end
    if aimPoint.y < MinHight then aimPoint.y = MinHight end
    I:SetLuaControlledMissileAimPoint(lti,mi,aimPoint.x,aimPoint.y,aimPoint.z)
end


-- corrects missile flight path based on enemy position, missile position, where you are aiming (waypoints work as well), the game time, additional time needed for waypoint navigation
-- Dont forget to run ClearMissileDataPG() as well to clear the list MissileDataPG !
MissileDataPG = {}
function MissilePredictionGuiadance(TargetInfo,LuaControlledMissileInfo,AimPointPosition,GameTime,Accuracy,MaxIterations,I)
    local MissileId = LuaControlledMissileInfo.Id
    if MissileDataPG[MissileId] == nil then MissileDataPG[MissileId] = {} end

    MissileDataPG[MissileId].LastAlive = GameTime

    local TargetPosition = TargetInfo.Position
    local TargetVelocity = TargetInfo.Velocity
    local AimPointOffset = AimPointPosition - TargetPosition
    -- calculate acceleration of the target
    if MissileDataPG[MissileId].TargetAcceleration == nil then
        TargetAcceleration = Vector3(0,0,0)
    else
        TargetAcceleration = (TargetVelocity - MissileDataPG[MissileId].TargetAcceleration) * 40
    end
    MissileDataPG[MissileId].TargetAcceleration = TargetVelocity



    local MissilePosition = LuaControlledMissileInfo.Position
    local MissileVelocity = LuaControlledMissileInfo.Velocity
    -- calculate acceleration of missile
    if MissileDataPG[MissileId].MissileVelocity == nil then
        MissileAcceleration = Vector3(0,0,0)
    else
        MissileAcceleration = (MissileVelocity - MissileDataPG[MissileId].MissileVelocity) * 40
    end
    MissileDataPG[MissileId].MissileVelocity = MissileVelocity

    local InterceptionTime = 0
    local Aim = TargetPosition + TargetVelocity * InterceptionTime + TargetAcceleration / 2 * InterceptionTime^2 
    local AimLast = Aim + Vector3(Accuracy,0,0)
    local step = 1
    while (Aim - AimLast).magnitude > Accuracy and step <= MaxIterations do
        step = step + 1
        Aim = TargetPosition + TargetVelocity * InterceptionTime + TargetAcceleration / 2 * InterceptionTime^2 
        InterceptionTime = (Aim - MissilePosition).magnitude / Vector3.Dot(MissileVelocity + MissileAcceleration*InterceptionTime, (Aim-MissilePosition).normalized)
    end
    return Aim
end

function ClearMissileDataPG(GameTime)
    for MissileId, Info in pairs(MissileDataPG) do
        if Info.LastAlive ~= GameTime then
            MissileDataPG[MissileId] = nil
        end
    end
end



function MyLog(I,priority,message)
    if priority <= DebugLevel then
        I:Log(message)
    end
end