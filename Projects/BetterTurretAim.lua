-- use spinners to build LUA controlled turrets


-- include the BetterTurretCodeName in the name of a spinner, in order to aim it
BetterTurretCodeName = "BT"

-- Define ConfigGroups to tell your BTs what ai to listen to and how to move
ConfigGroups =  {{BetterTurretIndex = "1", AiName = "Ai_1", AimingBehaviour = {SlowAimCone = 10, DegPerSecMax = 60, DegPerSecMin = 20}}
                }
-- also add the BetterTurretIndex to all BetterTurrets names that should be controlled by the ai with AiName
-- a valid name with those default config would be "BT 1" or "h1Bv   uBT534 T111"

ERROR  = 0  -- shows errors
UPDATE = 20 -- shows the effect of the code
SYSTEM = 30 -- shows the calculations
DebugLevel = SYSTEM



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
        ParentRotation = Quaternion.Euler(I:GetConstructPitch(), I:GetConstructYaw(), I:GetConstructRoll())
    else
        -- if placed on another BT, we need to get its target global rotation
        if BetterTurret.PlacedOnBT then
            ParentRotation = BetterTurrets[BetterTurret.BTParentKey].TargetRotationLast
            I:Log("using rotation: "..tostring(ParentRotation).." as ParentRotation")
        else
            ParentRotation = I:GetSubConstructInfo(Parent).Rotation
        end
    end
    local AxisGlobal = ParentRotation * IdleRotation * Vector3.up -- GlobalSpace

    local TargetInfo = I:GetTargetInfo(BetterTurret.AiIndex, 0)
    local target -- GlobalSpace
    if TargetInfo.Valid then
        target = TargetInfo.AimPointPosition
    else
        target = Vector3(0,0,0)
    end
    local TargetDirection = (target - Position).normalized -- GlobalSpace
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

    if math.abs(AngleDif) > DeltaAngle then
        if math.abs(AngleDif) < SlowAimCone then
            AngleShould = AngleIs + DeltaAngle * TurnDirection
        else
            AngleShould = AngleIs + DegPerSecMax/40 * TurnDirection
        end
    end
    I:SetSpinBlockRotationAngle(BT_ID, AngleShould)
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