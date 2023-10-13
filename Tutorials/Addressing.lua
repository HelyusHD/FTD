-- video link: https://youtu.be/pijuWLsm7-k

CodeWord = "3"

function Listing(I)
    ListingDone = true

    local StuffIWantToAddress = {}
    for index = 0, I:GetAllSubconstructsCount()-1 do
        local SubConstructIdentifier = I:GetSubConstructIdentifier(index)
        if index == 0 then SubConstructIdentifier = 0 end
        I:Log("SubConstructIdentifier: "..SubConstructIdentifier)
        for weaponIndex = 0 ,I:GetWeaponCountOnSubConstruct(SubConstructIdentifier) do
            local WeaponBlockInfo = I:GetWeaponBlockInfoOnSubConstruct(SubConstructIdentifier, weaponIndex)
            if WeaponBlockInfo.Valid then
                I:Log("UPDATE:   found valid weapon")
                if string.find(WeaponBlockInfo.CustomName, CodeWord) then
                    table.insert(StuffIWantToAddress, {SubConstructIdentifier = SubConstructIdentifier, weaponIndex = weaponIndex})
                    I:Log("UPDATE:   weaponIndex: "..weaponIndex.. " added to list")
                end
            end 
        end
    end
    return StuffIWantToAddress
end

function Update(I)
    I:ClearLogs()
    if ListingDone == true then
        for key, val in pairs(StuffIWantToAddress) do
            I:Log("weapon: "..key.." with name: "..I:GetWeaponBlockInfoOnSubConstruct(val.SubConstructIdentifier, val.weaponIndex).CustomName)
        end
    else
        StuffIWantToAddress = Listing(I)
    end
end



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
