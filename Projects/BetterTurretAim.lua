TurretCodeName = "BT"



function FindAllSubconstructs(I, TurretCodeName)
    local ChosenSubconstructs = {}
    local SubconstructsCount = I:GetAllSubconstructsCount()
    for index = 0, SubconstructsCount do
        local SubConstructIdentifier = I:GetSubConstructIdentifier(index)
        if string.find(I:GetSubConstructInfo(SubConstructIdentifier).CustomName, CodeWord) then
            table.insert(ChosenSubconstructs, SubConstructIdentifier)
        end
    end
    return ChosenSubconstructs
end