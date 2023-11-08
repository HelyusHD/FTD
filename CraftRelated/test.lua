LegCodeWord = "WSLeg"
DebugLevel = 50


-- defines the movement of the fod of the leg in relation to the hight of the fod
function LegCurve(h,a)
    local x = (-h/40)^2 + math.abs(h)/4 + a * 0.7
    local y = -h
    return Vector3(x,y,0)
end


-- finds angles in a triangle. one corner is in the origin, one corner is at (x,y) and 2 side lengt are given as well (a and b)
-- is used to find angles of pinners to move end of leg at position (x,y)
function GetLegAngle(x,y,a,b)
    local alpha = math.acos((a^2+x^2+y^2-b^2)/(2*a*math.sqrt(x^2+y^2)))
    local betha = -math.acos((a^2+b^2-x^2-y^2)/(2*a*b))
    return {alpha=alpha, betha=betha}
end


-- inverts the order of a table
function ReverseTable(tab)
    for i = 1,  math.floor(#tab/2), 1 do
        tab[i], tab[#tab-i+1] = tab[#tab-i+1], tab[i]
    end
    return tab
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


-- loads all the spinners of all the legs in a list
-- calculates lenght of the segments legs are made out of
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


-- this runs once init was successfull and it controls the legs
function WaterSkimmerUpdate(I)
    local ConstructRoll = I:GetConstructRoll()
    local ConstructPitch = I:GetConstructPitch()
    local ConstructYaw = I:GetConstructYaw()
    for key, Leg in pairs(WSLegs) do
        local Parents = Leg.Parents
        local LocalLegPosition = I:GetSubConstructInfo(Parents[1]).LocalPosition
        local Com = I:GetConstructCenterOfMass()

        local Pos1 = I:GetSubConstructInfo(Parents[1]).Position
        local Pos5 = I:GetSubConstructInfo(Parents[5]).Position
        local h =  -Pos1.y - 6

        local Lenght1 = Leg.InitialLegPieceVector[2].magnitude
        local Lenght2 = Leg.InitialLegPieceVector[3].magnitude

        local FodPos = LegCurve(h,Lenght2)
        --FodPos = FodPos + Quaternion.Inverse(Quaternion.Euler(ConstructRoll / 180 * math.pi, ConstructYaw / 180 * math.pi, ConstructPitch / 180 * math.pi)) * LocalLegPosition - LocalLegPosition
        FodPos.y = FodPos.y - (Quaternion.Euler(ConstructRoll / 180 * math.pi, ConstructYaw / 180 * math.pi, ConstructPitch / 180 * math.pi) * (LocalLegPosition + Pos5 - Pos1)).y
        local Angles = GetLegAngle(FodPos.x,FodPos.y,Lenght1,Lenght2)

        if  LocalLegPosition.x < 0 then
            Angles = GetLegAngle(FodPos.x,FodPos.y,Lenght1,Lenght2)
            if (Lenght1 + Lenght2)*0.95 > math.sqrt(FodPos.x^2+FodPos.y^2) then
                local alpha = math.pi/2+math.atan(FodPos.y/FodPos.x)-Angles.alpha
                local betha = Angles.betha
                alpha = alpha * 180 / math.pi
                betha = betha * 180 / math.pi
                I:SetSpinBlockRotationAngle(Parents[1], 0)
                I:SetSpinBlockRotationAngle(Parents[2], alpha)
                I:SetSpinBlockRotationAngle(Parents[3], betha)
                I:SetSpinBlockRotationAngle(Parents[4], -alpha-betha - ConstructRoll)
                I:SetSpinBlockRotationAngle(Parents[5], ConstructPitch)
                I:SetSpinBlockRotationAngle(Leg.DefiningSCI, 0)
            end
        else
            Angles = GetLegAngle(FodPos.x,FodPos.y,Lenght1,Lenght2)
            if (Lenght1 + Lenght2)*0.95 > math.sqrt(FodPos.x^2+FodPos.y^2) then
                local alpha = math.pi/2+math.atan(FodPos.y/FodPos.x)-Angles.alpha
                local betha = Angles.betha
                alpha = alpha * 180 / math.pi
                betha = betha * 180 / math.pi
                I:SetSpinBlockRotationAngle(Parents[1], 0)
                I:SetSpinBlockRotationAngle(Parents[2], alpha)
                I:SetSpinBlockRotationAngle(Parents[3], betha)
                I:SetSpinBlockRotationAngle(Parents[4], -alpha-betha + ConstructRoll)
                I:SetSpinBlockRotationAngle(Parents[5], -ConstructPitch)
                I:SetSpinBlockRotationAngle(Leg.DefiningSCI, 0)
            end
        end

        
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