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


-- here comes an example calculation
function Update(I)
    I:ClearLogs()
    local Target = {Position=Vector3(1000,100,0),Velocity=Vector3(10,0,0),Acceleration=Vector3(12,-4,40)}
    local Pos = Vector3(0,0,0)
    local Vel = 800
    local Mass = 1
    local Drag = 0.01 -- if 100 m/s fast, experiences 1 N of force
    local MaxIterationSteps = 100
    local Accuracy = 1

    local result = TargetPrediction(I,Target,Pos,Vel,Mass,Drag,MaxIterationSteps,Accuracy)
    if result.Valid then
        I:Log("InterceptionPoint: "..tostring(result.InterceptionPoint).."   InterceptionTime: "..tostring(result.InterceptionTime))
    else
        I:Log("no solution")
    end
end
