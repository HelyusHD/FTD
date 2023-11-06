CodeName = "9"


function Init(I)
    InitDone = true
    local JustAList = {}
    for index = 0, I:GetAllSubconstructsCount()-1 do
        local SubConstructIdentifier = I:GetSubConstructIdentifier(index)
        local SubConstructInfo = I:GetSubConstructInfo(SubConstructIdentifier)
        if SubConstructInfo.CustomName == CodeName then
            table.insert(JustAList, SubConstructIdentifier)
        end
    end
    return JustAList
end




function Update(I)
    if InitDone == true then
    else
        JustAList = Init(I)
    end
    for key, SubConstructIdentifier in pairs(JustAList) do
        I:Log("key: "..key.." val: "..SubConstructIdentifier)
    end
end