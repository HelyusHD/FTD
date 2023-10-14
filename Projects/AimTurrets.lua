function FindAllSubconstructs(I, CodeWord)
    local ChosenSubconstructs = {}
    local SubconstructsCount = I:GetAllSubconstructsCount()
    for index = 0, SubconstructsCount-1 do
        local SubConstructIdentifier = I:GetSubConstructIdentifier(index)
        local SubConstructInfo = I:GetSubConstructInfo(SubConstructIdentifier)
        if SubConstructInfo.Valid then
        if string.find(SubConstructInfo.CustomName, CodeWord) then
            local GlobalPosition = SubConstructInfo.Position
            for index_02 = -1, SubconstructsCount-1 do
                local SubConstructIdentifier_02 = I:GetSubConstructIdentifier(index_02)
                if index_02 == -1 then SubConstructIdentifier_02 = 0 end
                for weaponIndex = 0 , I:GetWeaponCountOnSubConstruct(SubConstructIdentifier_02)-1 do
                    if GlobalPosition == I:GetWeaponBlockInfoOnSubConstruct(SubConstructIdentifier_02, weaponIndex).Position then
                        table.insert(ChosenSubconstructs, {SubConstructIdentifier = SubConstructIdentifier, weaponIndex = weaponIndex})
                    end
                end
            end
        end
    end
    end
    return ChosenSubconstructs
end


function AimTurret(I,weaponIndex,SubConstructIdentifier,angle)
    local BlockInfo = I:GetWeaponBlockInfo(weaponIndex)
    local ParentRotation
    local SubSpaceId = I:GetParent(BlockInfo.SubConstructIdentifier)
    if SubSpaceId == 0 then
        ParentRotation = Quaternion.Euler(I:GetConstructPitch(), I:GetConstructYaw(), I:GetConstructRoll())
    else
        ParentRotation = I:GetSubConstructInfo(I:GetParent(BlockInfo.SubConstructIdentifier)).Rotation
    end
    local SubConstructIdleRotation = I:GetSubConstructIdleRotation(SubConstructIdentifier)
    local RotaionAxis = SubConstructIdleRotation * Vector3.up
    local DefaultFront = SubConstructIdleRotation * Vector3.forward
    local AimDirection = (ParentRotation) * (Quaternion.AngleAxis(angle, RotaionAxis) * DefaultFront)
    I:AimWeaponInDirection(weaponIndex,AimDirection.x,AimDirection.y,AimDirection.z,0)
end


function Update(I)
    I:ClearLogs()
    local angle = 45
    for key, val in pairs(FindAllSubconstructs(I, "test")) do
        AimTurret(I,val.weaponIndex,val.SubConstructIdentifier,angle)
    end
end