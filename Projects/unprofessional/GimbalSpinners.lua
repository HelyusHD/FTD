-- the first pinner (all other spinners are stacked onto this first spinner)
-- needs to have the GimbalCodeWord in its name
GimbalCodeWord = "gimbal"


-- rotates 5 stacked spinners to perform a quaternion rotation
-- only the 1,3,5 th spinner will be rotated
-- all of those 3 spinners stay at the same coordinate
function GimbalSpinner(I,SubConstructIdentifier,Rotation)
    local SubConId_2 = I:GetParent(SubConstructIdentifier)
    local SubConId_3 = I:GetParent(SubConId_2)
    local SubConId_4 = I:GetParent(SubConId_3)
    local SubConId_5 = I:GetParent(SubConId_4)
    local Parent = I:GetParent(SubConId_5)
    local ParentRotation
    if Parent == 0 then
        ParentRotation = Quaternion.Euler(I:GetConstructPitch(), I:GetConstructYaw(), I:GetConstructRoll())
    else
        ParentRotation = I:GetSubConstructInfo(Parent).Rotation
    end
    local eulerAngles = (Quaternion.Inverse(I:GetSubConstructIdleRotation(SubConId_5)) * Quaternion.Inverse(ParentRotation) * Rotation).eulerAngles
    local SubConId = SubConstructIdentifier
    I:SetSpinBlockRotationAngle(SubConId, eulerAngles.z)
    I:SetSpinBlockRotationAngle(SubConId_3, -eulerAngles.x)
    I:SetSpinBlockRotationAngle(SubConId_5, eulerAngles.y)
end



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

function Update(I)
    local Direction = Vector3(0,0,1)
    local Rotation = Quaternion.FromToRotation(Vector3.forward, Direction)
    for key, SubConstructIdentifier in pairs(FindAllSubconstructs(I,GimbalCodeWord)) do
        GimbalSpinner(I,SubConstructIdentifier,Rotation)
    end
end
