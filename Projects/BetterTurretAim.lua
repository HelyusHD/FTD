-- use spinners to build LUA controlled turrets


AzimuthSpinnerCodeName = "am"
ElevationSpinnerCodeName = "ev"

-- add the BetterTurretIndex to all BetterTurrets that should be controlled by the ai with AiName
AimGroups = {{AiName = "Ai_1",BetterTurretIndex = "1"}}


ERROR = 0
UPDATE = 20
DebugLevel = UPDATE



function FindAllSubconstructs(I, CodeWord)
    local ChosenSubconstructs = {}
    local SubconstructsCount = I:GetAllSubconstructsCount()
    for index = 0, SubconstructsCount-1 do
        local SubConstructIdentifier = I:GetSubConstructIdentifier(index)
        I:Log(I:GetSubConstructInfo(SubConstructIdentifier).CustomName.." hi "..SubConstructIdentifier)
        if string.find(I:GetSubConstructInfo(SubConstructIdentifier).CustomName, CodeWord) then
            table.insert(ChosenSubconstructs, SubConstructIdentifier)
 
        end
    end
    return ChosenSubconstructs
end


function InitBT(I)
    BTinit = true
    BetterTurrets = {}
    ChosenSubconstructs = FindAllSubconstructs(I,AzimuthSpinnerCodeName)
    if #ChosenSubconstructs == 0 then
        MyLog(I,ERROR,"ERROR:   found no turrets to control")
        BTinit = false
    end
    for key, SubConstructIdentifier in pairs(ChosenSubconstructs) do
        local AzimuthTurret = SubConstructIdentifier
        local ElevationTurrets = {}
        local ChildrenCount = I:GetSubconstructsChildrenCount(SubConstructIdentifier)
        for index = 0, ChildrenCount-1 do
            local SubConstructChildIdentifier = I:GetSubConstructChildIdentifier(SubConstructIdentifier, index)
            if I:IsTurret(SubConstructChildIdentifier) then
                if I:GetSubConstructInfo(SubConstructChildIdentifier).CustomName == ElevationTurretCodeName then
                    table.insert(ElevationTurrets,SubConstructChildIdentifier)
                end
            end
        end
        local ATIdleRotation = I:GetSubConstructIdleRotation(SubConstructIdentifier)
        AiIndex = -1
        for tmp, AimGroup in pairs(AimGroups) do
            if string.find(I:GetSubConstructInfo(SubConstructIdentifier).CustomName, AimGroup.BetterTurretIndex) then
                for MainframeIndex = 0, I:GetNumberOfMainframes()-1 do
                    if I:Component_GetBlockInfo(26,MainframeIndex).CustomName == AimGroup.AiName then AiIndex = MainframeIndex end
                end
            end
        end
        BetterTurrets[key] = {AzimuthTurret = AzimuthTurret, ElevationTurrets = ElevationTurrets, ATIdleRotation = ATIdleRotation, ATParent = I:GetParent(SubConstructIdentifier), AiIndex = AiIndex}
    end
end


function BetterTurretsUpdate(I)
    for key, BetterTurret in pairs(BetterTurrets) do
        local AT = BetterTurret.AzimuthTurret
        local ATInfo = I:GetSubConstructInfo(AT)
        local ATPosition = ATInfo.Position
        local ATRotation = ATInfo.Rotation
        local ATAxis = ATRotation * Vector3.up
        local ATIdleRotation = BetterTurret.ATIdleRotation
        local ATParent = BetterTurret.ATParent
        local ParentRotation
        if ATParent == 0 then
            ParentRotation = Quaternion.Euler(I:GetConstructRoll(), I:GetConstructYaw(), I:GetConstructPitch())
        else
            ParentRotation = I:GetSubConstructInfo(ATParent).Rotation
        end

        --local target = Vector3(0,0,0)
        local TargetInfo = I:GetTargetInfo(BetterTurret.AiIndex, 0)
        I:Log(BetterTurret.AiIndex)
        local target
        if TargetInfo.Valid then
            target = TargetInfo.AimPointPosition
        else
            target = Vector3(0,0,0)
        end
        local TargetDirection = (target - ATPosition).normalized
        local ProjectedDirection = Quaternion.AngleAxis(90, ATAxis) * Vector3.Cross(TargetDirection, ATAxis)
        local angle = Vector3.Angle(ProjectedDirection, ParentRotation * Quaternion.Inverse(ATIdleRotation) * Vector3.forward)

        local CurrentAngle = Quaternion.Angle(ATInfo.LocalRotation, ATIdleRotation)

        I:Log("CurrentAngle = "..CurrentAngle)

        I:SetSpinBlockRotationAngle(AT, angle)
        MyLog(I,UPDATE,"UPDATE:   aiming spinner "..AT.." at "..angle.." degrees")
        MyLog(I,UPDATE,"UPDATE:   spinner "..AT.." pointing "..tostring(ATRotation * Vector3.forward))
    end
end


function Update(I)
    --I:ClearLogs()
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