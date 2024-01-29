--------------
-- Settings --
--------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

MissileControllers =  { 
    --   LaunchpadName    ControllingAiName    MissileBehaviourName     GuidanceName
        {"missiles 01",   "missile ai 01",     "Diving01",              "Default01"},
        {"missiles 02",   "missile ai 01",     "Straight01",            "Apn01"}
    }
    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------
    -- Here is a list of behaviours I implemented:
    MissileBehaviours = {
    --  BehaviourType    FlightBehaviourName   CruisingAltitude   DivingRadius
        {"Diving",       "Diving01",            200,               500         }, -- flies on CruisingAltitude till being within DivingRadius, when it strickes down on enemy
    
    --  BehaviourType    FlightBehaviourName   AimPointUpShift    DivingRadius
        {"Bombing",      "Bombing01",           30,                20          },
    
    --  BehaviourType    FlightBehaviourName     Radius      HightOffset     MaxHight    MinHight    WhiggleRadius   T
        {"Orbit",        "Orbit01",               200,        50,             600,        15,         5,              2},
    
    --  BehaviourType    FlightBehaviourName
        {"Straight",      "Straight01"}
    }
    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------
    -- Here is a list of guidances I implemented:
    MissileGuidances = {
    --  GuidanceType    GuidanceName    LockingAngle    UnlockingAngle  PropConst
        {"APN",         "Apn01",        20,             60,             2.65},
    
    --  GuidanceType    GuidanceName
        {"Default",     "Default01"}
    }
    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------
    -- here comes my code --
    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------
    ---Enumerations for Logging purposes
    ERROR = 0
    WARNING = 1
    SYSTEM = 2
    LISTS = 3
    VECTORS = 4
    DebugLevel = SYSTEM
    -- I marked lines where I need to add more code. with "#EDITHERE"
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
        -- iterates MissileControllers
        for MissileControllerId, MissileControllerData in pairs(MissileControllers) do
            if MissileControllerData.Valid then
                local MissileBehaviour = MissileBehaviours[MissileControllerData.MissileBehaviourId]
                local MissileGuidance = MissileGuidances[MissileControllerData.MissileGuidanceId]
                local TargetInfo = I:GetTargetInfo(MissileControllerData.MainframeId, 0)
                local AimPointPosition = TargetInfo.AimPointPosition
                local BehaviourType = MissileBehaviour[1]
                local GameTime = I:GetGameTime()
    
                -- iterates launchpads
                for _, luaTransceiverIndex in pairs(MissileControllerData.luaTransceiverIndexes) do
                    -- iterates missiles
                    for missileIndex=0 , I:GetLuaControlledMissileCount(luaTransceiverIndex)-1 do
                        local matched = false
                        local Id = I:GetLuaControlledMissileInfo(luaTransceiverIndex,missileIndex).Id
                        if MissileData[Id] == nil then MissileData[Id] = {} end
                        MissileData[Id].Alive = true
    
                        -- if the MissileController has a prediction routine enabled, the AimPointPosition will be adjusted
                        local AimPoint = AimPointPosition
                        if MissileGuidance ~= nil then
                            if MissileGuidance[1] == "Default" then AimPoint = AimPoint
                            elseif MissileGuidance[1] == "APN" then AimPoint = ApnGuidance(I,TargetInfo,AimPointPosition,luaTransceiverIndex,missileIndex,MissileGuidance)
                            end
                        end
    
                        -- here the correct MissileControl function is selected
                        if      BehaviourType == "Straight"      then MissileControlStraight(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint); matched = true
                        elseif  BehaviourType == "Diving"        then MissileControlDiving(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint); matched = true
                        elseif  BehaviourType == "CustomCurve"   then MissileControlCustomCurve(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint); matched = true
                        elseif  BehaviourType == "Bombing"       then MissileControlBomb(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint); matched = true
                        elseif  BehaviourType == "Orbit"         then MissileControlOrbit(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint); matched = true
                        end
                        -- more behaviours to come #EDITHERE
    
                        if not matched then MyLog(I,WARNING,"WARNING:  MissileController with LaunchpadName ".. MissileControllerData[1].. " has no working MissileBehaviour!") end
                    end
                end
            end
        end
        -- deletes dead missiles from the table
            for Id, missile in pairs (MissileData) do
                if missile.Alive == true then
                    MissileData[Id].Alive = false
                else
                    MissileData[Id] = nil
                end
            end
    end
    
    
    
    -- creates lists of all the launchpads Ids so addressing them is optimised
    -- finds Ids of controlling ai mainframes
    -- finds Id of MissileBehaviour
    function GeneralGuidanceInit(I)
        I:ClearLogs()
        MyLog(I,SYSTEM,"Running GeneralGuidanceInit")
        GeneralGuidanceInitDone = false
        local ErrorDetected = false
        local AtLeastOneSystemWorking = false
    
        -- a list containing a set of data for each missile
        MissileData = {}
    
        -- iterates MissileControllers
        local LuaTransceiverCount = I:GetLuaTransceiverCount()
        for MissileControllerId, MissileControllerData in pairs(MissileControllers) do
            local LaunchpadName = MissileControllerData[1]
            local ControllingAiName = MissileControllerData[2]
            local MissileBehaviourName = MissileControllerData[3]
            local PredictionName = MissileControllerData[4]
    
            local MissileControllerIsSetUpCorrect = true
    
            -- finds all the launchpads Ids
            local LaunchpadIds = {}
            for luaTransceiverIndex=0 , LuaTransceiverCount-1 do
                local LuaTransceiverInfo = I:GetLuaTransceiverInfo(luaTransceiverIndex)
                if LuaTransceiverInfo.CustomName == LaunchpadName then
                    table.insert(LaunchpadIds,luaTransceiverIndex)
                end
            end
            MissileControllers[MissileControllerId].luaTransceiverIndexes = LaunchpadIds
            if #LaunchpadIds == 0 then MyLog(I,WARNING,"WARNING:  MissileController with LaunchpadName "..LaunchpadName.. " has no assigned launchpads!"); MissileControllerIsSetUpCorrect = false end
    
            -- iterating ai mainframes
            for index=0 ,I:Component_GetCount(26)-1 do -------------------------------------------------------------------------------------------------- not sure about indexing
                if I:Component_GetBlockInfo(26,index).CustomName == ControllingAiName then
                    MissileControllers[MissileControllerId].MainframeId = index
                end
            end
            if MissileControllers[MissileControllerId].MainframeId == nil then MyLog(I,WARNING,"WARNING:  GuiadanceGroup with LaunchpadName "..LaunchpadName.. " has no assigned ai mainframe!"); MissileControllerIsSetUpCorrect = false end
    
            -- iterating MissileBehaviours
            for MissileBehaviourId, MissileBehaviour in pairs(MissileBehaviours) do
                -- checks if the MissileGuidance group can find a MissileBehaviour
                if MissileBehaviourName == MissileBehaviour[2] then
                    MissileControllers[MissileControllerId].MissileBehaviourId = MissileBehaviourId
                end
            end
            if MissileControllers[MissileControllerId].MissileBehaviourId == nil then MyLog(I,WARNING,"WARNING:  GuiadanceGroup with LaunchpadName "..LaunchpadName.. " has no configurated MissileBehaviour!"); MissileControllerIsSetUpCorrect = false end
            
    
            -- iterating MissileGuidances
            for MissileGuidanceId, MissileGuidance in pairs(MissileGuidances) do
                -- checks if the MissileGuidance group can find a MissileBehaviour
                if PredictionName == MissileGuidance[2] then
                    MissileControllers[MissileControllerId].MissileGuidanceId = MissileGuidanceId
                end
            end
            if MissileControllers[MissileControllerId].MissileGuidanceId == nil then MyLog(I,WARNING,"WARNING:  GuiadanceGroup with LaunchpadName "..LaunchpadName.. " has no configurated MissileGuidance!"); MissileControllerIsSetUpCorrect = false end
            
    
            
    
            MissileControllers[MissileControllerId].Valid = MissileControllerIsSetUpCorrect
            if MissileControllerIsSetUpCorrect then AtLeastOneSystemWorking = true end
        end
    
        if ErrorDetected == false and AtLeastOneSystemWorking == true then
            GeneralGuidanceInitDone = true
        else
            MyLog(I,SYSTEM,"GeneralGuidanceInit failed")
        end
    end
    
    
    
    function MissileControlStraight(I,lti,mi,MissileBehaviour,AimPointPosition)
        local  aimPoint = AimPointPosition
        I:SetLuaControlledMissileAimPoint(lti,mi,aimPoint.x,aimPoint.y,aimPoint.z)
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
            MissileData[MissileInfo.Id] = {}
        else
            if Position.y > CruisingAltitude then
                MissileData[MissileInfo.Id].Waypoint01 = true -- vertical launch done
            end
    
            if (AimPointPosition - Vector3(Position.x,AimPointPosition.y,Position.z)).magnitude < DivingRadius then
                MissileData[MissileInfo.Id].Waypoint02 = true -- cruising done
            end
    
            if MissileData[MissileInfo.Id].Waypoint01 ~= true then
                aimPoint = Position + Vector3(0,10,0)
    
            elseif MissileData[MissileInfo.Id].Waypoint02 ~= true then
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
            MissileData[MissileInfo.Id] = {}
            MissileData[MissileInfo.Id].LaunchPosition = Position
            MissileData[MissileInfo.Id].m_apt_InitialPlaneDistance = m_apt_PlaneDistance
        else
            local x = MissileData[MissileInfo.Id].m_apt_InitialPlaneDistance /2
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
            -- calculates at what rate we are getting closer to the enemie, so we can adjust the diving angle
            if MissileData[MissileInfo.Id].m_apt_VectorLast ~= nil then
                --ClosingVelocity = (m_apt_Vector - MissileData[MissileInfo.Id].m_apt_VectorLast) / (TimeSinceLaunch - MissileData[MissileInfo.Id].TimeSinceLaunchLast)
                local VectorA = Vector3(m_apt_Vector.x,0,(m_apt_Vector.z))
                VectorB = Vector3(MissileData[MissileInfo.Id].m_apt_VectorLast.x,0,MissileData[MissileInfo.Id].m_apt_VectorLast.z)
                ClosingVelocityXZ = (VectorA - VectorB) / (TimeSinceLaunch - MissileData[MissileInfo.Id].TimeSinceLaunchLast)
    
                -- if we fall faster than we get closer in XZ, we miss the target, so we slow the falling rate by aiming up
                if math.abs(MissileInfo.Velocity.y) > ClosingVelocityXZ.magnitude * SettingA then
                    aimPoint = Vector3(AimPointPosition.x,MissileInfo.Position.y + m_apt_PlaneVector.magnitude,AimPointPosition.z)
                end
            end
        end
        -- resets MissileData for a new missile
        if TimeSinceLaunch < 0.1 then
            MissileData[MissileInfo.Id] = {}
        else
            MissileData[MissileInfo.Id].m_apt_VectorLast = m_apt_Vector
            MissileData[MissileInfo.Id].TimeSinceLaunchLast = TimeSinceLaunch
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
    
    
    
    
    function ApnGuidance(I,TargetInfo,AimPointPosition,luaTransceiverIndex,missileIndex,MissileGuidance)
        local MissileInfo = I:GetLuaControlledMissileInfo(luaTransceiverIndex,missileIndex)
        local TargetPosition = AimPointPosition
        local MissilePosition = MissileInfo.Position
        local TargetVelocity = TargetInfo.Velocity
        local MissileVelocity = MissileInfo.Velocity
    
        local LockingAngle = MissileGuidance[3]
        local UnlockingAngle = MissileGuidance[4]
        local PropConst = MissileGuidance[5]
    
        local V = TargetVelocity - MissileVelocity
        local R = TargetPosition - MissilePosition
    
        if MissileData[MissileInfo.Id].ApnInfo == nil then
            MissileData[MissileInfo.Id].ApnInfo = {
                TickTimeLast = I:GetGameTime(),
                AimPointLast = R,
                Locked = false,
                DistanceLast = R.magnitude
            }
        end
    
        if not MissileData[MissileInfo.Id].ApnInfo.Locked and Vector3.Angle(R,MissileVelocity) < LockingAngle then
            MissileData[MissileInfo.Id].ApnInfo.Locked = true
        end
        if Vector3.Angle(R,MissileVelocity) > UnlockingAngle then
            MissileData[MissileInfo.Id].ApnInfo.Locked = false
        end
    
        if not MissileData[MissileInfo.Id].ApnInfo.Locked then
            MissileData[MissileInfo.Id].ApnInfo.TickTimeLast = I:GetGameTime()
            MissileData[MissileInfo.Id].ApnInfo.AimPointLast = R
            return AimPointPosition
        else
            local N = PropConst
            local LateralAcceleration = N * Vector3.Cross(V, Vector3.Cross(R, V)) / R.magnitude^2
            local w = Vector3.Cross(MissileVelocity, LateralAcceleration) / MissileVelocity.magnitude^2
            local dt = (I:GetGameTime()-MissileData[MissileInfo.Id].ApnInfo.TickTimeLast)
            local ApnVector = Quaternion.AngleAxis(w.magnitude*180/math.pi * dt, w.normalized) * (MissileData[MissileInfo.Id].ApnInfo.AimPointLast)
            local number = Vector3.Cross(V, Vector3.Cross(R, V)).magnitude 
            ApnVector = ApnVector.normalized * 500
                MissileData[MissileInfo.Id].ApnInfo.TickTimeLast = I:GetGameTime()
                MissileData[MissileInfo.Id].ApnInfo.AimPointLast = ApnVector
    
            return MissilePosition + ApnVector
        end
    end
    
    function MyLog(I,priority,message)
        if priority <= DebugLevel then
            I:Log(message)
        end
    end