-- MAKE SURE TO READ THE "Readme" FILE ON MY GITHUB!!!
-- link: https://github.com/HelyusHD/FTD/tree/main/Projects/GeneralMissileGuidance.lua

-- ||| SETTINGS
    function Settings()

    --------------
    -- Settings --
    --------------
    
        BreadboardInstalled = true
        -----------------------------------------------------------------------------------------
        MissileControllers =  { 
    
        --   LaunchpadName    ControllingAiName    MissileBehaviourName     GuidanceName    Size
            {"missiles 01",   "AIM missile",       "Straight01",            "Pg01",        "medium"},
            {"missiles 02",   "AIM missile",       "Straight01",            "PgR",         "medium"}
        }
    
    
        -----------------------------------------------------------------------------------------
        MissileBehaviours = {
    
        --  BehaviourType    MissileBehaviourName   CruisingAltitude   DivingRadius  PredictionTime
            {"Diving",       "Diving01",            300,               200,          2},
        
        --  BehaviourType    MissileBehaviourName   AimPointUpShift    DivingRadius
            {"Bombing",      "Bombing01",           30,                20},
        
        --  BehaviourType    MissileBehaviourName   Radius      HightOffset     MaxHight    MinHight    WhiggleRadius   T
            {"Orbit",        "Orbit01",             400,        50,             600,        30,         5,              2},
        
        --  BehaviourType    MissileBehaviourName   MaxHight    MinHight
            {"Straight",     "Straight01",          800,        2}
        }
    
        -----------------------------------------------------------------------------------------
        MissileGuidances = {
    
        --  GuidanceType    GuidanceName    LockingAngle    UnlockingAngle  PropConst
            {"APN",         "Apn01",        20,             60,             2.65},
    
        --  GuidanceType    GuidanceName
            {"PG",          "Pg01"},
            {"PG_rework",   "PgR"},
        
        --  GuidanceType    GuidanceName
            {"Default",     "Default01"}
        }
    end
    

    -----------------------------------------------------------------------------------------
    -- Here you can decide after how many seconds new settings are checked and applied
    -- Set to -1 to disable, once you have decided on your final settings
    UpdateSettingsInterval = 2

    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------

    -- here comes my code --
    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------

    ---Enumerations for Logging purposes
    ERROR = 0
    WARNING = 1
    SYSTEM = 2
    UPDATE = 3
    LISTS = 4
    VECTORS = 5
    DebugLevel = SYSTEM
    -- I marked lines where I need to add more code. with "#EDITHERE"
    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------

-- ||| UPDATE
    
    -- This function is called each game tick by the game engine
    -- The object named "I" contains a bunch of data related to the game
    function Update(I)
        GeneralMissileGuidance(I)
    end
    
    -- This is the main function organising my project
    function GeneralMissileGuidance(I)
        if GeneralMissileGuidanceInitDone ~= true then
            GeneralMissileGuidanceInit(I)
        else
            -- keeps loading settings to notice changed settings
            if UpdateSettingsInterval ~= 0 then
                if SettingsTick == nil then SettingsTick = 0 end
                SettingsTick = SettingsTick + 1
                if SettingsTick >= UpdateSettingsInterval * 40 then
                    SettingsTick = 0
                    GeneralMissileGuidanceInit(I)
                end
            end
            GeneralMissileGuidanceUpdate(I)
        end
    end
    
    -- This is what controls the launchpads
    function GeneralMissileGuidanceUpdate(I)
        -- iterates MissileControllers
        for MissileControllerId, MissileControllerData in pairs(MissileControllers) do
            if MissileControllerData.Valid then
                local MissileBehaviour = MissileBehaviours[MissileControllerData.MissileBehaviourId]
                local MissileGuidance = MissileGuidances[MissileControllerData.MissileGuidanceId]
                local TargetInfo = I:GetTargetInfo(MissileControllerData.MainframeId, 0)
                local AimPointPosition = TargetInfo.AimPointPosition
                local MissileSize = MissileControllerData[5]
                -- iterates launchpads
                for _, luaTransceiverIndex in pairs(MissileControllerData.luaTransceiverIndexes) do
                    -- iterates missiles
                    for missileIndex=0 , I:GetLuaControlledMissileCount(luaTransceiverIndex)-1 do
                        local Id = I:GetLuaControlledMissileInfo(luaTransceiverIndex,missileIndex).Id
                        if MissileData[Id] == nil then MissileData[Id] = {} end
                        MissileData[Id].Alive = true

                        CorrectLuaGuidanceError(I,luaTransceiverIndex,missileIndex,MissileSize,MissileControllerData.SizeScaling)
                        local AimPoint = AimPointPosition + MissileData[Id].LuaGuidanceError.ECMError - MissileData[Id].LuaGuidanceError.MissileError
                        AimPoint = MissileControllerData.Guiadance(I,TargetInfo,AimPoint,luaTransceiverIndex,missileIndex,MissileGuidance)
                        MissileControllerData.Behaviour(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint)
                    end
                end
            end
        end
        -- deletes dead missiles from the table
            for Id, missile in pairs(MissileData) do
                if missile.Alive == true then
                    MissileData[Id].Alive = false
                else
                    MissileData[Id] = nil
                end
            end
    end
    
-- ||| INIT

    -- creates lists of all the launchpads Ids so addressing them is optimised
    -- finds Ids of controlling ai mainframes
    -- finds Id of MissileBehaviour
    function GeneralMissileGuidanceInit(I)
        ClearMyLogs(I)
        Settings()
        MyLog(I,UPDATE,"UPDATE:   Initializing code at GameTime: "..I:GetGameTime())
        GeneralMissileGuidanceInitDone = false
        local ErrorDetected = false
        local AtLeastOneSystemWorking = false
        -- a list containing a set of data for each missile
        if MissileData == nil then MissileData = {} end
        -- iterates MissileControllers
        local LuaTransceiverCount = I:GetLuaTransceiverCount()
        for MissileControllerId, MissileControllerData in pairs(MissileControllers) do
            local LaunchpadName = MissileControllerData[1]
            local ControllingAiName = MissileControllerData[2]
            local MissileBehaviourName = MissileControllerData[3]
            local GuidanceName = MissileControllerData[4]
            local MissileSize = MissileControllerData[5]
            MyLog(I,SYSTEM,"—————————### LAUNCHPADS NAMED: "..LaunchpadName.." ###—————————")
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
            if #LaunchpadIds == 0 then MyLog(I,WARNING,"[✗]: MissileController has no assigned launchpads!"); MissileControllerIsSetUpCorrect = false end
            -- assigning ai mainframes
            for index=0 ,I:Component_GetCount(26)-1 do -------------------------------------------------------------------------------------------------- not sure about indexing
                if I:Component_GetBlockInfo(26,index).CustomName == ControllingAiName then
                    MissileControllers[MissileControllerId].MainframeId = index
                end
            end
            if MissileControllers[MissileControllerId].MainframeId == nil then MyLog(I,WARNING,"[✗]: GuiadanceGroup has no assigned ai mainframe!"); MissileControllerIsSetUpCorrect = false end
            -- assigning MissileBehaviours
            local BehaviourType
            for MissileBehaviourId, MissileBehaviour in pairs(MissileBehaviours) do
                -- checks if the MissileGuidance group can find a MissileBehaviour
                if MissileBehaviourName == MissileBehaviour[2] then
                    MissileControllers[MissileControllerId].MissileBehaviourId = MissileBehaviourId
                    BehaviourType = MissileBehaviour[1]
                    if      MissileBehaviour[1] == "Straight"      then MissileControllers[MissileControllerId].Behaviour = function(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint) MissileControlStraight(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint) end
                    elseif  MissileBehaviour[1] == "Diving"        then MissileControllers[MissileControllerId].Behaviour = function(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint) MissileControlDiving(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint) end
                    elseif  MissileBehaviour[1] == "CustomCurve"   then MissileControllers[MissileControllerId].Behaviour = function(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint) MissileControlCustomCurve(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint) end
                    elseif  MissileBehaviour[1] == "Bombing"       then MissileControllers[MissileControllerId].Behaviour = function(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint) MissileControlBomb(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint) end
                    elseif  MissileBehaviour[1] == "Orbit"         then MissileControllers[MissileControllerId].Behaviour = function(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint) MissileControlOrbit(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPoint) end
                    -- more behaviours to come #EDITHERE
                    else
                        MyLog(I,WARNING,"[✗]: The MissileBehaviour \""..MissileBehaviourName.."\" has no working BehaviourType!"); MissileControllerIsSetUpCorrect = false
                    end
                end
            end
            if MissileControllers[MissileControllerId].MissileBehaviourId == nil then
                MyLog(I,WARNING,"[✗]: GuiadanceGroup has no configurated MissileBehaviour!"); MissileControllerIsSetUpCorrect = false
            end
            -- assigning MissileGuidances
            for MissileGuidanceId, MissileGuidance in pairs(MissileGuidances) do
                -- checks if the MissileGuidance group can find a MissileBehaviour
                if GuidanceName == MissileGuidance[2] then
                    MissileControllers[MissileControllerId].MissileGuidanceId = MissileGuidanceId
                    if     MissileGuidance[1] == "Default"  then MissileControllers[MissileControllerId].Guiadance = function(I,TargetInfo,AimPointPosition,luaTransceiverIndex,missileIndex,MissileGuidance) return AimPointPosition end
                    elseif MissileGuidance[1] == "APN"      then MissileControllers[MissileControllerId].Guiadance = function(I,TargetInfo,AimPointPosition,luaTransceiverIndex,missileIndex,MissileGuidance) return ApnGuidance(I,TargetInfo,AimPointPosition,luaTransceiverIndex,missileIndex,MissileGuidance) end
                    elseif MissileGuidance[1] == "PG"       then MissileControllers[MissileControllerId].Guiadance = function(I,TargetInfo,AimPointPosition,luaTransceiverIndex,missileIndex,MissileGuidance) return PredictionGuidance(I,TargetInfo,AimPointPosition,luaTransceiverIndex,missileIndex,MissileGuidance) end
                    elseif MissileGuidance[1] == "PG_rework"       then MissileControllers[MissileControllerId].Guiadance = function(I,TargetInfo,AimPointPosition,luaTransceiverIndex,missileIndex,MissileGuidance) return PredictionGuidanceRework(I,TargetInfo,AimPointPosition,luaTransceiverIndex,missileIndex,MissileGuidance) end
                    else
                        MyLog(I,WARNING,"[✗]: The MissileGuidance \""..GuidanceName.."\" has no working GuidanceType!"); MissileControllerIsSetUpCorrect = false
                    end
                    if BehaviourType == "Diving" and MissileGuidance[1] == "APN" then MyLog(I,WARNING,"[✗]: Dont use a APN with a Diving behaviour!"); MissileControllerIsSetUpCorrect = false end
                end
            end
            if MissileControllers[MissileControllerId].MissileGuidanceId == nil then
                MyLog(I,WARNING,"[✗]: GuiadanceGroup has no configurated MissileGuidance!"); MissileControllerIsSetUpCorrect = false
            end
            -- checking missile size
            if MissileSize ~= "small" and MissileSize ~= "medium" and MissileSize ~= "large" and MissileSize ~= "huge" then
                MyLog(I,WARNING,"[✗]: GuiadanceGroup has no Size selected!"); MissileControllerIsSetUpCorrect = false
            end
            -- checking if anything triggered MissileControllerIsSetUpCorrect being "false"
            MissileControllers[MissileControllerId].Valid = MissileControllerIsSetUpCorrect
            if MissileControllerIsSetUpCorrect then
                AtLeastOneSystemWorking = true
                MyLog(I,SYSTEM,"[✓]: Loaded "..#LaunchpadIds.." launchpads using:\n        - behaviour: "..MissileBehaviourName.."\n        - prediction: "..GuidanceName)
            end
            -- density of components and offset of position, depending on missile size
            if     MissileSize == "small"  then
                MissileControllers[MissileControllerId].SizeScaling = 0.125
            elseif MissileSize == "medium" then
                MissileControllers[MissileControllerId].SizeScaling = 0.25 + 1
            elseif MissileSize == "large"  then
                MissileControllers[MissileControllerId].SizeScaling = 0.5 + 1
            elseif MissileSize == "huge"   then
                MissileControllers[MissileControllerId].SizeScaling = 1
            else
                MissileControllers[MissileControllerId].SizeScaling = 0.25 + 1
                MyLog(I,WARNING,"[ ! ]: Missile size is not given!")
            end
        end
        if BreadboardInstalled ~= true then MyLog(I,WARNING,"[ ! ]: Did you install the bread board? \"BreadboardInstalled\" is still set to false!")end
        if ErrorDetected == false and AtLeastOneSystemWorking == true then
            GeneralMissileGuidanceInitDone = true
        else
            MyLog(I,SYSTEM,"_____________________________________________")
            MyLog(I,SYSTEM,"[✗]: Not a single system could be loaded !!!")
        end
    end

-- ||| behaviours   
    
    function MissileControlStraight(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPointPosition)
        local MaxHight = MissileBehaviour[3]
        local MinHight = MissileBehaviour[4]
        local  aimPoint = AimPointPosition
        if aimPoint.y > MaxHight then aimPoint.y = MaxHight end
        if aimPoint.y < MinHight then aimPoint.y = MinHight end
        I:SetLuaControlledMissileAimPoint(luaTransceiverIndex,missileIndex,aimPoint.x,aimPoint.y,aimPoint.z)
    end
    
    -- guides missiles along waypoints
    function MissileControlDiving(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPointPosition)
    
        local MissileInfo = I:GetLuaControlledMissileInfo(luaTransceiverIndex,missileIndex)
        local CruisingAltitude = MissileBehaviour[3]
        local DivingRadius = MissileBehaviour[4]
        local PredictionTime = MissileBehaviour[5]
    
        local TimeSinceLaunch = MissileInfo.TimeSinceLaunch
        local Position = MissileInfo.Position
        local PredictedPosition = Position + MissileInfo.Velocity * PredictionTime
    
        -- resets MissileData for a new missile
        if TimeSinceLaunch < 0.1 then
            MissileData[MissileInfo.Id] = {
                Waypoint01 = false,
                Waypoint02 = false
            }
        else
            if PredictedPosition.y > CruisingAltitude then
                MissileData[MissileInfo.Id].Waypoint01 = true -- vertical launch done
            end
    
            if (AimPointPosition - Vector3(PredictedPosition.x,AimPointPosition.y,PredictedPosition.z)).magnitude < DivingRadius then
                MissileData[MissileInfo.Id].Waypoint02 = true -- cruising done
            end
    
            if MissileData[MissileInfo.Id].Waypoint01 ~= true then
                local ScalingFactor = 500
                aimPoint = Position + Vector3(0,ScalingFactor,0) + MissileInfo.Velocity.normalized * ScalingFactor / 100
    
            elseif MissileData[MissileInfo.Id].Waypoint02 ~= true then
                aimPoint = Vector3(AimPointPosition.x,CruisingAltitude,AimPointPosition.z)
            else
                local R = AimPointPosition - MissileInfo.Position
                if Vector3.Angle(R,MissileInfo.Velocity) < 50 then
                    local AimPointCorrection = (R.normalized - MissileInfo.Velocity.normalized) * math.abs(MissileInfo.Position.y - AimPointPosition.y)
                    aimPoint = AimPointPosition + AimPointCorrection
                else
                    aimPoint = AimPointPosition
                end
            end
            I:SetLuaControlledMissileAimPoint(luaTransceiverIndex,missileIndex,aimPoint.x,aimPoint.y,aimPoint.z)
        end
    end
    
    -- #EDITHERE
    -- not done yet
    function MissileControlCustomCurve(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPointPosition)
        local MissileInfo = I:GetLuaControlledMissileInfo(luaTransceiverIndex,missileIndex)
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
            local x = 1 - m_apt_PlaneDistance / MissileData[MissileInfo.Id].m_apt_InitialPlaneDistance -- progress of the flight from 0 tp 1
            local height = AimPointPosition.y + 0
        end
    end
    
    -- lets missiles with no propulsion glide onto the enemie
    function MissileControlBomb(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPointPosition)
        local MissileInfo = I:GetLuaControlledMissileInfo(luaTransceiverIndex,missileIndex)
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
    
        I:SetLuaControlledMissileAimPoint(luaTransceiverIndex,missileIndex,aimPoint.x,aimPoint.y,aimPoint.z)
    end
    
    -- lets missliles orbit around the AimPointPosition
    function MissileControlOrbit(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPointPosition)
        local Radius = MissileBehaviour[3]
        local HightOffset = MissileBehaviour[4]
        local MaxHight = MissileBehaviour[5]
        local MinHight = MissileBehaviour[6]
        local WhiggleRadius = MissileBehaviour[7]
        local T = MissileBehaviour[8]
        local MissileInfo = I:GetLuaControlledMissileInfo(luaTransceiverIndex,missileIndex)
        local Position = MissileInfo.Position
        local alpha = math.atan2(AimPointPosition.x - Position.x, AimPointPosition.z - Position.z) * 180/math.pi + 10
        local r =  Quaternion.AngleAxis(alpha, Vector3.up) * -Vector3.forward
    
        local WhiggleAxis = Vector3(-r.z,0,r.x).normalized
        local Whiggle = Quaternion.AngleAxis(I:GetTime() * 360 / T, WhiggleAxis) * Vector3.up * WhiggleRadius
    
        local aimPoint = AimPointPosition + r * Radius + Vector3(0,HightOffset,0) + Whiggle
        if aimPoint.y > MaxHight then aimPoint.y = MaxHight end
        if aimPoint.y < MinHight then aimPoint.y = MinHight end
        I:SetLuaControlledMissileAimPoint(luaTransceiverIndex,missileIndex,aimPoint.x,aimPoint.y,aimPoint.z)
    end

-- ||| signal processing   
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

    function PredictionGuidanceRework(I,TargetInfo,AimPointPosition,luaTransceiverIndex,missileIndex,MissileGuidance)
        local MissileInfo = I:GetLuaControlledMissileInfo(luaTransceiverIndex,missileIndex)
        local TargetPosition = AimPointPosition
        local MissilePosition = MissileInfo.Position
        local TargetVelocity = TargetInfo.Velocity
        local MissileVelocity = MissileInfo.Velocity

        if MissileData[MissileInfo.Id].TargetVelocityLast == nil then
            MissileData[MissileInfo.Id].TargetVelocityLast = TargetVelocity
            MissileData[MissileInfo.Id].AimCorrectionVectorLast = Vector3(0,0,0)
            MissileData[MissileInfo.Id].PredictedTargetPositionLast = TargetPosition
        end
        local TargetAcceleration = (MissileData[MissileInfo.Id].TargetVelocityLast - TargetVelocity) * 40
        MissileData[MissileInfo.Id].TargetVelocityLast = TargetVelocity

        local PredictedTargetPosition = TargetPosition + MissileData[MissileInfo.Id].AimCorrectionVectorLast
        local R = PredictedTargetPosition - MissilePosition
        local ApproachingSpeed = ((MissileData[MissileInfo.Id].PredictedTargetPositionLast - MissilePosition).magnitude - (PredictedTargetPosition - MissilePosition).magnitude) * 40--Vector3.Dot(MissileVelocity, R.normalized)
        if ApproachingSpeed <= 0 then ApproachingSpeed = Vector3.Dot(MissileVelocity, R.normalized) end
        if ApproachingSpeed > 0 then

            local InterceptionTime = R.magnitude / ApproachingSpeed

            if MissileData[MissileInfo.Id].AimCorrectionVectorLast.magnitude < 10 then
                PredictedTargetPosition = TargetPosition + TargetVelocity * InterceptionTime + TargetAcceleration * InterceptionTime^2 / 2
            end
            local PTP_last_iteration = PredictedTargetPosition 
            local Iteration = 1
            while ((PredictedTargetPosition - PTP_last_iteration).magnitude > 1 and Iteration <= 10) or Iteration == 1 do
                Iteration = Iteration + 1
                PTP_last_iteration = PredictedTargetPosition

                PredictedTargetPosition = TargetPosition + TargetVelocity * InterceptionTime + TargetAcceleration * InterceptionTime^2 / 2
                InterceptionTime = math.min((PredictedTargetPosition - MissilePosition).magnitude / ApproachingSpeed, ApproachingSpeed*2/TargetVelocity.magnitude)

                --R = PredictedTargetPosition - MissilePosition
                --ApproachingSpeed = Vector3.Dot(MissileVelocity, R.normalized)
            end
            if tmp3w63 == nil then tmp3w63 = I:GetTime() end
            if I:GetTime() > tmp3w63 + 0.5 then
                I:LogToHud("SYSTEM:   iterations: "..Iteration.." AimCorrectionVector: "..tostring(PredictedTargetPosition - TargetPosition).." InterceptionTime: "..InterceptionTime)
                tmp3w63 = I:GetTime()
            end
            MissileData[MissileInfo.Id].AimCorrectionVectorLast = Vector3(0,0,0) --PredictedTargetPosition - TargetPosition
            MissileData[MissileInfo.Id].PredictedTargetPositionLast = PredictedTargetPosition
        else
            return TargetPosition
        end
        return PredictedTargetPosition
    end

    function PredictionGuidance(I,TargetInfo,AimPointPosition,luaTransceiverIndex,missileIndex,MissileGuidance)
        local MissileInfo = I:GetLuaControlledMissileInfo(luaTransceiverIndex,missileIndex)
        local TargetPosition = AimPointPosition
        local MissilePosition = MissileInfo.Position
        local TargetVelocity = TargetInfo.Velocity
        local MissileVelocity = MissileInfo.Velocity

        if MissileData[MissileInfo.Id].TargetVelocityLast == nil then
            MissileData[MissileInfo.Id].TargetVelocityLast = TargetVelocity
        end
        local TargetAcceleration = (MissileData[MissileInfo.Id].TargetVelocityLast - TargetVelocity) * 40
        MissileData[MissileInfo.Id].TargetVelocityLast = TargetVelocity

        local R = TargetPosition - MissilePosition
        local ApproachingSpeed = Vector3.Dot(MissileVelocity, R.normalized)

        local InterceptionTime = R.magnitude / ApproachingSpeed
        local PredictedTargetPosition = TargetPosition + TargetVelocity * InterceptionTime + TargetAcceleration * InterceptionTime^2 / 2
        local Iteration = 1

        while math.abs((PredictedTargetPosition - TargetPosition).magnitude / ApproachingSpeed - InterceptionTime) > 0.01 and Iteration <= 10 do
            Iteration = Iteration + 1
            PredictedTargetPosition = TargetPosition + TargetVelocity * InterceptionTime + TargetAcceleration * InterceptionTime^2 / 2
            InterceptionTime = (PredictedTargetPosition - TargetPosition).magnitude / ApproachingSpeed
            R = PredictedTargetPosition - MissilePosition
            ApproachingSpeed = Vector3.Dot(MissileVelocity, R.normalized)
        end

        return PredictedTargetPosition
    end

    -- corrects for two kinds of errors
    -- 1. stability error
    -- 2. ECM error
    function CorrectLuaGuidanceError(I,luaTransceiverIndex,missileIndex,MissileSize,SizeScaling)
        local Parts = I:GetMissileInfo(luaTransceiverIndex,missileIndex).Parts
        local MissileInfo = I:GetLuaControlledMissileInfo(luaTransceiverIndex,missileIndex)
        local  Id = MissileInfo.Id
        local StabilityModyfier
        missilelength = #Parts
        if MissileData[Id].LuaGuidanceError == nil then
            MissileData[Id].LuaGuidanceError = {}
            local LenghtOffset = I:GetLuaTransceiverInfo(luaTransceiverIndex).Forwards*(missilelength * SizeScaling)
            if BreadboardInstalled == true then 
                StabilityModyfier = 10 * (1-I:GetPropulsionRequest(13))
            else
                StabilityModyfier = 0
            end
            MissileData[Id].LuaGuidanceError.StabilityErrorDir = (I:GetLuaTransceiverInfo(luaTransceiverIndex).Position - (MissileInfo.Position + LenghtOffset)).normalized
            MissileData[Id].LuaGuidanceError.MissileError = (I:GetLuaTransceiverInfo(luaTransceiverIndex).Position - MissileInfo.Position + LenghtOffset) + StabilityModyfier * MissileData[Id].LuaGuidanceError.StabilityErrorDir
            MissileData[Id].LuaGuidanceError.ECMError = Vector3(0,0,0)
        end
        if BreadboardInstalled == true then 
            StabilityModyfier = 10 * (1-I:GetPropulsionRequest(13))
        else
            StabilityModyfier = 0
        end
        local StabilityMiss = StabilityModyfier * MissileData[Id].LuaGuidanceError.StabilityErrorDir
        if MissileData[Id].LuaGuidanceError.MissileLastPos == nil then MissileData[Id].LuaGuidanceError.MissileLastPos = MissileInfo.Position + (MissileData[Id].LuaGuidanceError.MissileError - StabilityMiss) end
        if MissileData[Id].LuaGuidanceError.SelfLastVel == nil then MissileData[Id].LuaGuidanceError.SelfLastVel = MissileInfo.Velocity end
        local Discrepancy = (MissileInfo.Position + (MissileData[Id].LuaGuidanceError.MissileError - StabilityMiss)) - (MissileData[Id].LuaGuidanceError.MissileLastPos + MissileData[Id].LuaGuidanceError.SelfLastVel / 40)
        MissileData[Id].LuaGuidanceError.SelfLastVel = MissileInfo.Velocity
        MissileData[Id].LuaGuidanceError.MissileLastPos = MissileInfo.Position+(MissileData[Id].LuaGuidanceError.MissileError - StabilityMiss)

        if (Discrepancy.magnitude > 5 and Discrepancy.magnitude < 200) or MissileData[Id].LuaGuidanceError.ECMError.magnitude > 5 then
            MissileData[Id].LuaGuidanceError.ECMError = MissileData[Id].LuaGuidanceError.ECMError + Discrepancy
        end
    end

-- ||| custom log

        FinalMessage = ""
        function MyLog(I,priority,Message)
            if priority <= DebugLevel then
                if FinalMessage == "" then
                    FinalMessage = Message
                else
                    FinalMessage = FinalMessage.."\n"..Message
                end
                I:ClearLogs()
                I:Log(FinalMessage)
            end
        end
        function ClearMyLogs(I)
            FinalMessage = ""
            I:ClearLogs()
        end