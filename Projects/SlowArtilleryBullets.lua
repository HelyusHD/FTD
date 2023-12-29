-- Set up a WeaponGroup to aim and fire all turrets whichs turret base is named like <WeaponName> says.
-- each WeaponGroup should contain weapons with the same BulletSpeed

--                      ControllingAiName   BulletSpeed     WeaponName
WeaponGroupsSetting = { {"Ai01",             100,            "aim this"},
                        {"Ai01",             70,             "aim this 02"}
                    }


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


function CreateWeaponList(I,CodeWord)
    local WeaponSystems = {}
    local Turrets = FindAllSubconstructs(I, CodeWord)
    for _, SubConstructIdentifier in pairs(Turrets) do
        for weaponIndex = 0 ,I:GetWeaponCount() - 1 do
            if SubConstructIdentifier == I:GetWeaponBlockInfo(weaponIndex).SubConstructIdentifier then
                table.insert(WeaponSystems, {SubConstructIdentifier = SubConstructIdentifier, weaponIndex = weaponIndex})
            end
        end
    end
    return WeaponSystems
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
        Vy = Dy/InterceptionTime - I:GetGravityForAltitude(Pos.y + Dy/2).y*InterceptionTime / 2
        local Vxz = math.sqrt(Vel^2 - Vy^2)
        Distance = (PredictedPosition - Pos).magnitude
        InterceptionTime = Distance/(Vel - (Vel*Drag/Mass * InterceptionTime^2 / 2))
        I:Log("Iteration: "..Iterations.."   PredictedPosition: "..tostring(PredictedPosition).."   InterceptionTime: "..InterceptionTime.."   Vxz: "..Vxz)
        if Vel^2 < Vy^2 then return {Valid = false} end
    end

    local Elevation = math.asin(Vy/Vel) * 180/math.pi
    local a = (Vector3(PredictedPosition.x,0,PredictedPosition.z) - Vector3(Pos.x,0,Pos.z)).normalized
    local AimingDirection = Quaternion.AngleAxis(Elevation, Vector3.Cross(a,Vector3.up).normalized) * a
    return {AimingDirection = AimingDirection, InterceptionPoint = PredictedPosition, InterceptionTime = InterceptionTime, Elevation = Elevation, Valid = true}
end


-- creates WeaponGroups == {} which contains a {} for each WeaponGroup
-- a WeaponGroup has information in order to fire a group of weapons:
-- BulletSpeed, WeaponSystems == {}, MainframeId
function SlowArtilleryInit(I)
    WeaponGroups = {}
    for WeaponGroupId, WeaponGroupInfo in pairs(WeaponGroupsSetting) do
        WeaponGroups[WeaponGroupId] = {}
        local ControllingAiName = WeaponGroupInfo[1]
        WeaponGroups[WeaponGroupId].BulletSpeed = WeaponGroupInfo[2]
        WeaponGroups[WeaponGroupId].WeaponSystems = CreateWeaponList(I,WeaponGroupInfo[3])

        -- iterating ai mainframes
        for index=0 ,I:Component_GetCount(26)-1 do -------------------------------------------------------------------------------------------------- not sure about indexing
            if I:Component_GetBlockInfo(26,index).CustomName == ControllingAiName then
                WeaponGroups[WeaponGroupId].MainframeId = index
            end
        end
    end
    SlowArtilleryUpdateDone = true
end


-- aims and fires WeaponGroups
function SlowArtilleryUpdate(I)
    if SlowArtilleryUpdateDone ~= true then
        SlowArtilleryInit(I)
    else
        for _, WeaponGroup in pairs(WeaponGroups) do
            local mainframeIndex = WeaponGroup.MainframeId
            local WeaponSystems = WeaponGroup.WeaponSystems
            local BulletSpeed = WeaponGroup.BulletSpeed
            local TargetInfo = I:GetTargetInfo(mainframeIndex, 0)
            if TargetInfo.Valid then
                for _, WeaponSystem in pairs(WeaponSystems) do
                    local Target = {Position = TargetInfo.AimPointPosition, Velocity = TargetInfo.Velocity, Acceleration = Vector3(0,0,0)}
                    local SubConstructIdentifier = WeaponSystem.SubConstructIdentifier
                    local weaponIndex = WeaponSystem.weaponIndex
                    local Pos = I:GetWeaponInfo(weaponIndex).GlobalFirePoint
                    local Vel = BulletSpeed
                    local Mass = 1
                    local Drag = 0
                    local MaxIterationSteps = 20
                    local Accuracy = 1
                    local aim = TargetPrediction(I,Target,Pos,Vel,Mass,Drag,MaxIterationSteps,Accuracy).AimingDirection
                    I:AimWeaponInDirection(weaponIndex, aim.x,aim.y,aim.z, 0)

                    -- checks if aim and CurrentDirection are parallel
                    if (I:GetWeaponInfo(weaponIndex).CurrentDirection * aim.normalized) < 0.01 then
                        I:FireWeapon(weaponIndex, 0)
                    end
                end
            end
        end
    end
end



function Update(I)
    SlowArtilleryUpdate(I)
end