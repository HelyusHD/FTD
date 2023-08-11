LegCodeWord = "WSLeg"
DebugLevel = 50



local function ReverseTable(tab)
    for i = 1,  math.floor(#tab/2), 1 do
        tab[i], tab[#tab-i+1] = tab[#tab-i+1], tab[i]
    end
    return tab
end


-- Function to approximate inverse of hight(alpha)
-- Parameters: h - the desired y(x) value, a - parameter a, b - parameter b
function approximateInverseFunction(h, a, b)
    local function hight(alpha)
        return math.cos(alpha) * a + math.cos(alpha * math.abs(math.cos(alpha / 2))) * b
    end

    -- Bisection method to approximate the inverse
    local epsilon = 1e-1 -- Desired accuracy
    local maxIterations = 20
    local left = -math.pi
    local right = 0
    local mid = (left + right) / 2

    for _ = 1, maxIterations do
        local value = hight(mid)
        local diff = value - h

        if math.abs(diff) < epsilon then
            return mid
        elseif diff < 0 then
            left = mid
        else
            right = mid
        end

        mid = (left + right) / 2
    end

    return nil -- No solution found within the specified iterations
end


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


-- output LIST: {Parent, ParentOfParent, ParentOfParentOfParent, ...}
-- returns list of parents with options:
-- <SubConstructIdentifier> what SubConstruct to start at
-- <Depths> limits steps of this search
function FindParentsOfSubconstruct(I,SubConstructIdentifier, Depths)
    local ChosenSubconstructs = {}
    if Depths == nil then Depths = 100 end
    for step = 1, Depths do
        local Parent = I:GetParent(SubConstructIdentifier)
        if Parent ~= 0 and Parent ~= -1 then
            ChosenSubconstructs[step] = Parent
            SubConstructIdentifier = Parent
        else
            return ChosenSubconstructs
        end
    end
    return ChosenSubconstructs
end


-- output LIST: {{SubConstructIdentifier1, {ParentsOf1}}, {SubConstructIdentifier2, {ParentsOf2}}, ...}
-- dependencies: FindAllSubconstructs(); FindParentsOfSubconstruct()
-- you can define structures where 1 spinner defines the setup
-- example: animation made out of 3 stacked spinners (name the spinner having no children)
function FindAllStructures(I, CodeWord, Depths)
    local Structures = {}
    local AllSubconstructs = FindAllSubconstructs(I, CodeWord)
    MyLog(I,50,"UPDATE:   found "..#AllSubconstructs.." Legs")
    for key, SubConstructIdentifier in pairs(AllSubconstructs) do
        table.insert(Structures, {DefiningSCI = SubConstructIdentifier, Parents = ReverseTable(FindParentsOfSubconstruct(I,SubConstructIdentifier, Depths))})
    end
    return Structures
end


function InitWaterSkimmer(I)
    init = true
    WSLegs = FindAllStructures(I, LegCodeWord, 5) -- list of all the legs of the water skimmer

    for key, Structure in pairs (WSLegs) do
        WSLegs[key].InitialLegPieceVector = {} -- the vectors connecting 2 joints 
        WSLegs[key].InitialSpinnerPosition = {} -- the positions of the joints
        local Parents = Structure.Parents

        for i = 1, #Parents do
            WSLegs[key].InitialSpinnerPosition[i] = I:GetSubConstructInfo(Parents[i]).Position
        end

        for i = 1, #Parents-1 do
            WSLegs[key].InitialLegPieceVector[i] = I:GetSubConstructInfo(Parents[i + 1]).Position - I:GetSubConstructInfo(Parents[i]).Position
        end
        WSLegs[key].InitialLegPieceVector[#Parents] = I:GetSubConstructInfo(Structure.DefiningSCI).Position - I:GetSubConstructInfo(#Parents).Position
    end
end


function WaterSkimmerUpdate(I)
    local ConstructRoll = I:GetConstructRoll()
    local ConstructPitch = I:GetConstructPitch()
    for key, Leg in pairs(WSLegs) do
        local Parents = Leg.Parents
        local LegInfo = I:GetSubConstructInfo(Parents[1])
        --local LocalLegPosition = LegInfo.LocalPosition
        local LocalLegPosition = I:GetSubConstructInfo(Parents[1]).LocalPosition
        local LegPosition = LegInfo.Position



        local h = -LegPosition.y - 4
        local Lenght1 = Leg.InitialLegPieceVector[2].magnitude
        local Lenght2 = Leg.InitialLegPieceVector[3].magnitude
        if h > Lenght1 - Lenght2 - 1 then h = Lenght1 - Lenght2 - 1 end
        if h < -Lenght1 - Lenght2 + 5 then h = -Lenght1 - Lenght2 + 1 end
        local alpha = approximateInverseFunction(h, Lenght1, -Lenght2)
        local betha = alpha * math.abs(math.cos(alpha/2))
        alpha = alpha * 180 / math.pi
        betha = betha * 180 / math.pi

        I:SetSpinBlockRotationAngle(Parents[1], 0)
        I:SetSpinBlockRotationAngle(Parents[2], -alpha)
        I:SetSpinBlockRotationAngle(Parents[3], alpha + betha)
        if LocalLegPosition.x < 0 then
            I:SetSpinBlockRotationAngle(Parents[4], -betha + ConstructRoll)
            I:SetSpinBlockRotationAngle(Parents[5], ConstructPitch)
        else
            I:SetSpinBlockRotationAngle(Parents[4], -betha - ConstructRoll)
            I:SetSpinBlockRotationAngle(Parents[5], -ConstructPitch)
        end
        I:SetSpinBlockRotationAngle(Leg.DefiningSCI, 0)
    end
end

function Update(I)
    if init == nil then
        InitWaterSkimmer(I)
    else
        WaterSkimmerUpdate(I)

    end
end


function MyLog(I,priority,message)
    if priority <= DebugLevel then
        I:Log(message)
    end
end