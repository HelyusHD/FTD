
-- output LIST: {SubConstructIdentifier1, SubConstructIdentifier2, SubConstructIdentifier3, ...}
-- returns a list of all subconstructs with condition:
-- <CodeWord> is part of CustomName
function FindAllSubconstructs(I, CodeWord)
    local ChosenSubconstructs = {}
    local SubconstructsCount = I:GetAllSubconstructsCount()
    for index = 0, SubconstructsCount do
        local SubConstructIdentifier = I:GetSubConstructIdentifier(index)
        local CustomName = I:GetSubConstructInfo(SubConstructIdentifier).CustomName
        if CustomName ~= nil then
            if string.find(CustomName, CodeWord) then
                table.insert(ChosenSubconstructs, SubConstructIdentifier)
            end
        end
    end
    return ChosenSubconstructs
end

-- creates a Leg object based on the RootBlock spinner (the spinner no other spinners are placed on)
function Leg_(I, RootBlock)
    local Leg = {}
    Leg.S1 = RootBlock
    Leg.S2 = I:GetParent(I:GetParent(Leg.S1))
    Leg.S3 = I:GetParent(I:GetParent(Leg.S2))
    return Leg
end



function MoveLeg(I,Leg,rot)

    --rotation
    local euler = (rot).eulerAngles
    I:SetSpinBlockRotationAngle(Leg.S3, euler.z)
    I:SetSpinBlockRotationAngle(Leg.S2, euler.y)
    I:SetSpinBlockRotationAngle(Leg.S1, euler.x)
end

function InitLegs(I)
    InitLegsDone = true
    local Legs = {}
    for LegIndex, RootBlock in pairs(FindAllSubconstructs(I, "t")) do
        table.insert(Legs, Leg_(I, RootBlock))
    end
    return Legs
end

function WaterSkiUpdate(I)
    local t = I:GetGameTime()
    local w = 0
    local r = 5
    local rot = Quaternion.Euler(0, 0, 0)
    for LegIndex, Leg in pairs(Legs) do
        MoveLeg(I,Leg,rot)
    end
end

function WaterSki(I)
    if InitLegsDone ~= true then
        Legs = InitLegs(I)
    else
        WaterSkiUpdate(I)
    end
end

function Update(I)
    WaterSki(I)
end