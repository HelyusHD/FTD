-- Set up a WeaponGroup to aim and fire all turrets whichs turret base is named like <WeaponName> says.
-- each WeaponGroup should contain weapons with the same BulletSpeed

--                      ControllingAiName   BulletSpeed     Mass    Drag    WeaponName  Rpm     AnimationName
WeaponGroupsSetting = { {"Ai01",             1004,          1,      0,      "group01",  400,     "recoil01"},
                        {"Ai01",             1004,          1,      0,      "group02",  100,     "recoil02"}
                      }


-- Weapons may have an animation. Create an AnimationSettings and refer to it in the WeaponGroupsSetting using the AnimationName.
-- The AnimationName decides what WeaponGroup will use what AnimationSetting.

-- AnimationType: There may be different kinds of animations.
-- AngleMax: max angle of the spinners used to create the animation.
-- Fraction: fraction = 4 means, that the animation will be pushed in by recoil for 25% of the time
--           and that it will use 75% of the time to extend back to starting position
-- SpinnerName: the name of the most outward spinner of 3 stacked spinners, which create the movement

--                    AnimationName     AnimationType   AngleMax    Fraction    SpinnerName
AnimationSettings = {{"recoil01",       "recoil",       10,         2,          "recoil"},
                     {"recoil02",       "recoil",       30,         4,          "recoil"}
                    }




---Enumerations for Logging purposes
ERROR = 0
WARNING = 1
SUCCESS = 2
SYSTEM = 3
LISTS = 4
VECTORS = 5
DebugLevel = SUCCESS

function MyLog(I,priority,message)
    if priority <= DebugLevel then
        I:Log(message)
    end
end


-- Function to calculate the mean of a lists values
function calculateMean(list)
    local sum = Vector3(0,0,0)

    -- Calculate the sum of all the values
    for _, value in ipairs(list) do
        sum = sum + value
    end

    -- Calculate the mean
    local mean = sum / #list

    return mean
end


-- returns leanght of lists containing nils
function NilListLenght(list)
    local a = 0
    for _,_ in pairs(list) do a = a+1 end
    return a
end


-- output LIST: {SubConstructIdentifier1, SubConstructIdentifier2, SubConstructIdentifier3, ...}
-- returns a list of all subconstructs with condition:
-- <CodeWord> is part of CustomName
function FindAllSubconstructs(I, CodeWord)
    local ChosenSubconstructs = {}
    local SubconstructsCount = I:GetAllSubconstructsCount()
    for index = 0, SubconstructsCount-1 do
        local SubConstructIdentifier = I:GetSubConstructIdentifier(index)
        if I:GetSubConstructInfo(SubConstructIdentifier).Valid then
            if string.find(I:GetSubConstructInfo(SubConstructIdentifier).CustomName, CodeWord) then
                table.insert(ChosenSubconstructs, SubConstructIdentifier)
            end
        else
            --ERROR
        end
    end
    return ChosenSubconstructs
end




-- This function calculates the AimingDirection, InterceptionPoint, InterceptionTime and barrel elevation
-- for a gun fireing a bullet on a moving target.
-- AimingDirection gives you the direction to aim the barrel.
-- The straightest flight curve is prioritised.

-- Target               = TargetInfoObject containing {Position=Vector3, Velocity=Vector3, Acceleration=Vector3}
-- Pos                  = Vector3 where the bullet spawns in global space
-- Vel                  = scalar speed of the bullet
-- Mass                 = bullet mass
-- Drag                 = Drag of the bullet in [N*s/m] (which are newton per, meter per second)
-- MaxIterationSteps    = maximum iterations to get more accurate
-- Accuracy             = Accuracy in meters of the aproximation

-- Drag is only aproximated as well. I recomend not using this for very slow bullets!

function TargetPrediction(I,Target,Pos,Vel,Mass,Drag,MaxIterationSteps,Accuracy)
    local Valid = false
    local Distance = (Target.Position - Pos).magnitude
    local PredictedPosition = Target.Position
    local InterceptionTime = Distance/Vel
    local PredictedPositionLast = Target.Position + Target.Position.normalized * (Accuracy+1)
    local Iterations = 0
    local Vy
    while (PredictedPosition - PredictedPositionLast).magnitude > Accuracy and Iterations < MaxIterationSteps do
        Iterations = Iterations + 1
        PredictedPositionLast = PredictedPosition
        PredictedPosition = Target.Position + Target.Velocity * InterceptionTime + Target.Acceleration * InterceptionTime^2 / 2
        local Dy = PredictedPosition.y - Pos.y
        -- Dy = Vy*t + g*t^2 /2
        Vy = Dy/InterceptionTime - I:GetGravityForAltitude(Pos.y + Dy/2).y*InterceptionTime / 2
        local Vxz = math.sqrt(Vel^2 - Vy^2)
        --Distance = (PredictedPosition - Pos).magnitude
        DistanceXz = Vector3(PredictedPosition.x - Pos.x, 0, PredictedPosition.z - Pos.z).magnitude
        InterceptionTime = DistanceXz/(Vxz - (Drag/Mass * InterceptionTime^2 / 2))
        MyLog(I,SYSTEM,"SYSTEM:   Iteration: "..Iterations.."   PredictedPosition: "..tostring(PredictedPosition).."   InterceptionTime: "..InterceptionTime.."   Vxz: "..Vxz)
        if Vel^2 < Vy^2 then
            Valid = false
            return {Valid = Valid}
        end
    end

    local Elevation = math.asin(Vy/Vel) * 180/math.pi
    local a = (Vector3(PredictedPosition.x,0,PredictedPosition.z) - Vector3(Pos.x,0,Pos.z)).normalized
    local AimingDirection = Quaternion.AngleAxis(Elevation, Vector3.Cross(a,Vector3.up).normalized) * a
    if AimingDirection ~= nil then
        Valid = true
    end
    return {AimingDirection = AimingDirection, InterceptionPoint = PredictedPosition, InterceptionTime = InterceptionTime, Elevation = Elevation, Valid = Valid}

end



-- keeps track of acceleration
function BetterTargetInfo(I, AiIndex, Prio)
    -- TargetInfos = {} init in LuaTurretsInit()
    local MeanOverN = 2 * 40
    local TargetInfo = I:GetTargetInfo(AiIndex, Prio)
    if TargetInfos[AiIndex] == nil then TargetInfos[AiIndex] = {} end
    if TargetInfos[AiIndex][Prio] == nil then TargetInfos[AiIndex][Prio] = {} end
    if TargetInfos[AiIndex][Prio].lastAccelerationValues == nil then TargetInfos[AiIndex][Prio].lastAccelerationValues = {} end
    if TargetInfos[AiIndex][Prio].LastUpdate == nil then TargetInfos[AiIndex][Prio].LastUpdate = I:GetTime() - 1/40 end
    if TargetInfo.Valid then
        if I:GetTime() ~= TargetInfos[AiIndex][Prio].LastUpdate then
            if TargetInfos[AiIndex][Prio].Velocity == nil then
                TargetInfos[AiIndex][Prio].Velocity = TargetInfo.Velocity
            end
            local Acceleration = (TargetInfo.Velocity - TargetInfos[AiIndex][Prio].Velocity) / (I:GetTime() - TargetInfos[AiIndex][Prio].LastUpdate)
            Acceleration.y = 0
            -- Add the current value of 'a' to the end of the table
            table.insert(TargetInfos[AiIndex][Prio].lastAccelerationValues, Acceleration)
            -- If the table has more than MeanOverN elements, remove the oldest element (at position 1, moves all elements down by 1)
            if #TargetInfos[AiIndex][Prio].lastAccelerationValues > MeanOverN then
                table.remove(TargetInfos[AiIndex][Prio].lastAccelerationValues, 1)
            end
            TargetInfos[AiIndex][Prio].Acceleration = calculateMean(TargetInfos[AiIndex][Prio].lastAccelerationValues)
            TargetInfos[AiIndex][Prio].Velocity = TargetInfo.Velocity
            TargetInfos[AiIndex][Prio].Position = TargetInfo.Position
            TargetInfos[AiIndex][Prio].AimPointPosition = TargetInfo.AimPointPosition
            TargetInfos[AiIndex][Prio].LastUpdate = I:GetTime()
        end
        return TargetInfos[AiIndex][Prio]
    else
        TargetInfos[AiIndex][Prio] = nil
        return  {
                Acceleration = Vector3(0,0,0),
                Velocity = Vector3(0,0,0),
                Position = Vector3(0,0,0),
                AimPointPosition = Vector3(0,0,0)
                }
    end
end



function Update(I)
    if DebugLevel > SUCCESS then I:ClearLogs() end
    LuaTurretsUpdate(I)
end



-- aims and fires WeaponGroups
function LuaTurretsUpdate(I)
    if LuaTurretsInitDone ~= true then
        LuaTurretsInit(I)
        if LuaTurretsInitDone == true then MyLog(I,SUCCESS,"SUCCESS:   LuaTurretsInit() done") end
    else
        for WeaponGroupIndex, WeaponGroup in pairs(WeaponGroups) do
            local mainframeIndex = WeaponGroup.MainframeId
            local WeaponSystems = WeaponGroup.WeaponSystems
            local BulletSpeed = WeaponGroup.BulletSpeed
            local Mass = WeaponGroup.Mass
            local Drag = WeaponGroup.Drag
            if I:GetAIFiringMode(mainframeIndex) == "On" then
                local TargetInfo = I:GetTargetInfo(mainframeIndex, 0)
                if TargetInfo.Valid then
                    for WeaponSystemIndex, WeaponSystem in pairs(WeaponSystems) do
                        local Target = BetterTargetInfo(I, mainframeIndex, 0)
                        local SubConstructIdentifier = WeaponSystem.SubConstructIdentifier
                        local weaponIndex = WeaponSystem.weaponIndex
                        local Pos = I:GetWeaponInfo(weaponIndex).GlobalFirePoint
                        local Vel = BulletSpeed
                        local MaxIterationSteps = 20
                        local Accuracy = 0.01
                        local Prediction = TargetPrediction(I,Target,Pos,Vel,Mass,Drag,MaxIterationSteps,Accuracy)
                        local aim = Prediction.AimingDirection
                        local fired = false
                        if Prediction.Valid then
                            I:AimWeaponInDirection(weaponIndex, aim.x,aim.y,aim.z, 0)
                              -- checks if aim and CurrentDirection are parallel
                            if 1 - Vector3.Dot(I:GetWeaponInfo(weaponIndex).CurrentDirection, aim.normalized) < 0.01 then
                                if WeaponGroup.Rpm ~= nil then
                                    if WeaponSystem.FiredLast + 60/WeaponGroup.Rpm < I:GetTime() then
                                        I:FireWeapon(weaponIndex, 0) ; fired = true
                                        WeaponSystems[WeaponSystemIndex].FiredLast = I:GetTime()
                                    end
                                else
                                    I:FireWeapon(weaponIndex, 0) ; fired = true
                                end
                            end
                        end
                        WeaponGroups[WeaponGroupIndex].WeaponSystems[WeaponSystemIndex].Animation = LuaTurretsAnimations(I, WeaponSystem.Animation, fired)
                    end
                end
            end
        end
    end
end



-- creates WeaponGroups == {} which contains a {} for each WeaponGroup
-- a WeaponGroup has information in order to fire a group of weapons:
-- BulletSpeed, WeaponSystems == {}, MainframeId
function LuaTurretsInit(I)
    LuaTurretsInitDone = true
    TargetInfos = {} -- used for BetterTargetInfo()
    WeaponGroups = {}
    for WeaponGroupId, WeaponGroupInfo in pairs(WeaponGroupsSetting) do
        WeaponGroups[WeaponGroupId] = weaponGroup(I,WeaponGroupInfo,AnimationSettings)
    end
    if NilListLenght(WeaponGroups) < 1 then 
        LuaTurretsInitDone = false
        MyLog(I,WARNING,"WARNING:   Could not load any WeaponGroup")
    end
end



-- attempt to define weaponGroup as an object
local function weaponGroup(I,WeaponGroupInfo,AnimationSettings)

    local function animationSetting(AnimationName)
        for _, AnimationSetting in pairs(AnimationSettings) do
            if AnimationSetting[1] == AnimationName then
                return AnimationSetting
            end
        end
    end

    local function weaponSystems()
        WeaponList = CreateWeaponList(I)
        if #WeaponList < 1 then
            MyLog(I,WARNING,"WARNING:   no turrets found named \""..WeaponList.."\"")
        else
            MyLog(I,SUCCESS,"SUCCESS:   found "..#WeaponList.." WeaponSystems named \""..WeaponGroupInfo[5].."\"")
        end
        return WeaponList
    end

    local function mainframeId()
        -- iterating ai mainframes
        local matched = false
        local Id
        for index=0 ,I:Component_GetCount(26)-1 do -------------------------------------------------------------------------------------------------- not sure about indexing
            if I:Component_GetBlockInfo(26,index).CustomName == WeaponGroupInfo[1] then
                matched = true
                    Id = index
                break
            end
        end
        if not matched then
            MyLog(I,WARNING,"WARNING:   Turrets named \""..WeaponGroup.WeaponName.."\" no AI named \""..WeaponGroupInfo[1].."\" found")
        end
        return Id
    end

    return {
        BulletSpeed = WeaponGroupInfo[2],
        Mass = WeaponGroupInfo[3],
        Drag = WeaponGroupInfo[4],
        WeaponName = WeaponGroupInfo[5],
        Rpm = WeaponGroupInfo[6],
        AnimationSetting = animationSetting(WeaponGroupInfo[7]),
        WeaponSystems = weaponSystems(),
        MainframeId = mainframeId()
    }
end