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

    local step  = 0
    while Aim - AimLast > Accuracy and step <= MaxIterations do
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
