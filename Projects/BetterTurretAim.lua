-- use spinners to build LUA controlled turrets


-- include the BetterTurretCodeName in the name of a spinner, in order to aim it
BetterTurretCodeName = "BT"

-- Define ConfigGroups to tell your BTs what ai to listen to and how to move
ConfigGroups =  {{BetterTurretIndex = "1", AiName = "Ai_1", AimingBehaviour = {SlowAimCone = 0, DegPerSecMax = 120, DegPerSecMin = 20}}
                }
-- also add the BetterTurretIndex to all BetterTurrets names that should be controlled by the ai with AiName
-- a valid name with those default config would be "BT 1" or "h1Bv   uBT534 T111"

ERROR  = 0  -- shows errors
UPDATE = 20 -- shows the effect of the code
SYSTEM = 30 -- shows the calculations
DebugLevel = UPDATE


function BetterTargetInfo(I, AiIndex, Prio)
    if TargetInfos == nil then TargetInfos = {} end
    local TargetInfo = I:GetTargetInfo(AiIndex, Prio)
    if TargetInfos[AiIndex] == nil then TargetInfos[AiIndex] = {} end
    if TargetInfos[AiIndex][Prio] == nil then TargetInfos[AiIndex][Prio] = {} end
    if TargetInfo.Valid then
        if I:GetTime() ~= TargetInfos[AiIndex][Prio].LastUpdate then
            if TargetInfos[AiIndex][Prio].VelocityLast == nil then
                TargetInfos[AiIndex][Prio].VelocityLast = TargetInfo.Velocity
            end
            local Acceleration = (TargetInfo.Velocity - TargetInfos[AiIndex][Prio].VelocityLast) * 40
            TargetInfos[AiIndex][Prio] =   {Acceleration = Acceleration, VelocityLast = TargetInfo.Velocity, LastUpdate = I:GetTime()}
        end
        return TargetInfos[AiIndex][Prio]
    else
        TargetInfos[AiIndex][Prio] = nil
        return  {
                Acceleration = Vector3(0,0,0),
                VelocityLast = Vector3(0,0,0)
                }
    end
end



-- This function calculates the InterceptionPoint, InterceptionTime and barrel elevation
-- for a gun fireing a bullet on a moving target.
-- The straightest flight curve is prioritised.
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
        MyLog(I,SYSTEM,"Iteration: "..Iterations.."   PredictedPosition: "..tostring(PredictedPosition).."   InterceptionTime: "..InterceptionTime.."   Vxz: "..Vxz)
        if Vel^2 < Vy^2 then return {Valid = false} end
    end

    local Elevation = math.asin(Vy/Vel) * 180/math.pi
    local a = (Vector3(PredictedPosition.x,0,PredictedPosition.z) - Vector3(Pos.x,0,Pos.z)).normalized
    local AimingDirection = Quaternion.AngleAxis(Elevation, Vector3.Cross(a,Vector3.up).normalized) * a
    return {AimingDirection = AimingDirection, InterceptionPoint = PredictedPosition, InterceptionTime = InterceptionTime, Elevation = Elevation, Valid = true}
end



-- Gets angle of spinner
function GetSpinnerAngle(I,SubConstructIdentifier)
    local IdleRotation = I:GetSubConstructIdleRotation(SubConstructIdentifier)
    return Vector3.SignedAngle(IdleRotation * Vector3.forward, I:GetSubConstructInfo(SubConstructIdentifier).LocalRotation * Vector3.forward, IdleRotation * Vector3.up)
end



function FindAllSubconstructs(I, CodeWord)
    local ChosenSubconstructs = {}
    local SubconstructsCount = I:GetAllSubconstructsCount()
    for index = 0, SubconstructsCount-1 do
        local SubConstructIdentifier = I:GetSubConstructIdentifier(index)
        if string.find(I:GetSubConstructInfo(SubConstructIdentifier).CustomName, CodeWord) then
            table.insert(ChosenSubconstructs, SubConstructIdentifier)
        end
    end
    return ChosenSubconstructs
end


function InitBT(I)
    BTinit = true
    BetterTurrets = {}
    ChosenSubconstructs = FindAllSubconstructs(I,BetterTurretCodeName)
    if #ChosenSubconstructs == 0 then
        MyLog(I,ERROR,"ERROR:   found no turrets to control")
        BTinit = false
    end
    for key, SubConstructIdentifier in pairs(ChosenSubconstructs) do
        local BT_ID = SubConstructIdentifier
        local IdleRotation = I:GetSubConstructIdleRotation(BT_ID)
        local AiIndex = -1
        local AimingBehaviour
        for tmp, ConfigGroup in pairs(ConfigGroups) do
            if string.find(I:GetSubConstructInfo(BT_ID).CustomName, ConfigGroup.BetterTurretIndex) then
                AimingBehaviour = ConfigGroup.AimingBehaviour
                for MainframeIndex = 0, I:GetNumberOfMainframes()-1 do
                    if I:Component_GetBlockInfo(26,MainframeIndex).CustomName == ConfigGroup.AiName then AiIndex = MainframeIndex end
                end
            end
        end
        BetterTurrets[key] = {BT_ID = BT_ID, IdleRotation = IdleRotation, Parent = I:GetParent(BT_ID), AiIndex = AiIndex, AimingBehaviour = AimingBehaviour, PlacedOnBT = false, TargetRotationLast = Quaternion.identity}
        -- findind BTs placed on BTs
        for key_01, BetterTurret_01 in pairs(BetterTurrets) do
            for key_02, BetterTurret_02 in pairs(BetterTurrets) do
                if BetterTurret_01.Parent == BetterTurret_02.BT_ID then
                    BetterTurrets[key_01].PlacedOnBT = true
                    BetterTurrets[key_01].BTParentKey = key_02
                end
            end
        end
    end
end


function AimBT(I,key,BetterTurret)
    local BT_ID = BetterTurret.BT_ID
    local SubConstructInfo = I:GetSubConstructInfo(BT_ID)
    local Position = SubConstructInfo.Position -- GlobalSpace
    local IdleRotation = BetterTurret.IdleRotation -- SubSpace
    local Parent = BetterTurret.Parent
    local ParentRotation -- GlobalSpace
    if Parent == 0 then
        --ParentRotation = Quaternion.Euler(I:GetConstructPitch()*math.pi/180/2, I:GetConstructYaw()*math.pi/180/2, I:GetConstructRoll()*math.pi/180/2)
        ParentRotation = Quaternion.Euler(I:GetConstructPitch(), I:GetConstructYaw(), I:GetConstructRoll())
    else
        -- if placed on another BT, we need to get its target global rotation
        if BetterTurret.PlacedOnBT then
            ParentRotation = BetterTurrets[BetterTurret.BTParentKey].TargetRotationLast
        else
            ParentRotation = I:GetSubConstructInfo(Parent).Rotation
        end
    end
    local AxisGlobal = ParentRotation * IdleRotation * Vector3.up -- GlobalSpace

    local TargetInfo = I:GetTargetInfo(BetterTurret.AiIndex, 0)
    if TargetInfo.Valid then
        local TargetInfo = {Position = TargetInfo.Position, Velocity = TargetInfo.Velocity, Acceleration = BetterTargetInfo(I, BetterTurret.AiIndex, 0).Acceleration}
        local Pos = Position
        local Vel = 1000
        local Mass = 1
        local Drag = 0
        local TargetPrediction = TargetPrediction(I,TargetInfo,Pos,Vel,Mass,Drag,100,1)
        if TargetPrediction.Valid then

            local TargetDirection = TargetPrediction.AimingDirection -- GlobalSpace
            --TargetDirection = Vector3(0,0,1)
            local ProjectedDirection = Vector3.ProjectOnPlane(TargetDirection, AxisGlobal) -- GlobalSpace
            BetterTurrets[key].TargetRotationLast = Quaternion.LookRotation(ProjectedDirection, AxisGlobal) --GlobalSpace
            local AngleShould = Vector3.SignedAngle(ParentRotation * (IdleRotation * Vector3.forward), ProjectedDirection, AxisGlobal) -- GlobalSpace
            MyLog(I,SYSTEM,"SYSTEM:   projection: "..tostring(ProjectedDirection).." mag.: "..ProjectedDirection.magnitude.." global rot. axis: "..tostring(AxisGlobal))
    
            local AimingBehaviour = BetterTurret.AimingBehaviour
            local SlowAimCone = AimingBehaviour.SlowAimCone
            local DegPerSecMax = AimingBehaviour.DegPerSecMax
            local DegPerSecMin = AimingBehaviour.DegPerSecMin
    
            local AngleIs = GetSpinnerAngle(I,BT_ID)
            local AngleDif = AngleIs - AngleShould
            local DeltaAngle = DegPerSecMax/40 * math.abs(AngleDif)/SlowAimCone
            if DeltaAngle < DegPerSecMin/40 then DeltaAngle = DegPerSecMin/40 end
    
            local TurnDirection
            if AngleDif > 0 then
                TurnDirection = -1
            else
                TurnDirection = 1
            end
    
            if math.abs(AngleDif) > DeltaAngle and AngleDif > 1 then
                if math.abs(AngleDif) < SlowAimCone then
                    AngleShould = AngleIs + DeltaAngle * TurnDirection
                else
                    AngleShould = AngleIs + DegPerSecMax/40 * TurnDirection
                end
            end
            I:SetSpinBlockRotationAngle(BT_ID, AngleShould)
        end
    end
end


function BetterTurretsUpdate(I)
    MyLog(I,UPDATE,"UPDATE:   BetterTurrets is controlling "..#BetterTurrets.." turrets")
    for key, BetterTurret in pairs(BetterTurrets) do
        AimBT(I,key,BetterTurret)
    end
end


function Update(I)
    I:ClearLogs()
    if BTinit == true then
        BetterTurretsUpdate(I)
    else
        InitBT(I)
    end
end


function MyLog(I,priority,message)
    if priority <= DebugLevel then
        I:Log(message)
    end
end 