-- Gets angle of spinner
function GetSpinnerAngle(I,SubConstructIdentifier)
    local IdleRotation = I:GetSubConstructIdleRotation(SubConstructIdentifier)
    return Vector3.SignedAngle(IdleRotation * Vector3.forward, I:GetSubConstructInfo(SubConstructIdentifier).LocalRotation * Vector3.forward, IdleRotation * Vector3.up)
end



function Update(I)
    I:ClearLogs()
    local SubconstructsCount = I:GetAllSubconstructsCount()
    for index = 0, SubconstructsCount-1 do
        local SubConstructIdentifier = I:GetSubConstructIdentifier(index)
        local SpinnerAngle = GetSpinnerAngle(I,SubConstructIdentifier)
        I:Log("spinner: "..SubConstructIdentifier.." named: "..I:GetSubConstructInfo(SubConstructIdentifier).CustomName.." is at angle: "..SpinnerAngle)
    end
end