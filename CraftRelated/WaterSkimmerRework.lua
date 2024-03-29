LegCodeWord = "WSLeg"
DebugLevel = 50



-- FodPos = (forward,up,right)
function GetLegAngle(FodPos,a,b)
    local yaw = math.atan2(FodPos.x , FodPos.z)
    local x = math.sqrt(FodPos.x^2 + FodPos.z^2)
    local y = -FodPos.y
    local alpha = math.pi/2 + math.atan(y/x) - math.acos((a^2+x^2+y^2-b^2)/(2*a*math.sqrt(x^2+y^2)))
    local betha = -math.acos((a^2+b^2-x^2-y^2)/(2*a*b))
    return {alpha=alpha, betha=betha, yaw=yaw}
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


-- loads all the spinners of all the legs in a list
-- calculates lenght of the segments legs are made out of
function InitWaterSkimmer(I)
    WSinit = true
    if WSLegs == nil then
        WSLegs = FindAllStructures(I, LegCodeWord, 7) -- list of all the legs of the water skimmer
    end
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
        WSLegs[key].IdleRotation = I:GetSubConstructIdleRotation(Parents[1])
        WSLegs[key].FlipX = (WSLegs[key].IdleRotation * Vector3.forward).x > 0
    end
end


function WaterSkimmerUpdate(I)
    local ConstructRoll = I:GetConstructRoll()
    local ConstructPitch = I:GetConstructPitch()
    local ConstructYaw = I:GetConstructYaw()
    local ConstructUpVector = I:GetConstructUpVector()
    local InverseCraftRotation = Quaternion.Inverse(Quaternion.Euler(ConstructPitch, -ConstructYaw, ConstructRoll))
    I:Log("line 135: InverseCraftRotation: "..tostring(InverseCraftRotation))
    for key, Leg in pairs(WSLegs) do
        local Parents = Leg.Parents
        local SubConstructInfo = I:GetSubConstructInfo(Parents[1])
        local GlobalLegPosition = SubConstructInfo.Position
        local LocalLegPosition = SubConstructInfo.LocalPosition
        local Lenght1 = Leg.InitialLegPieceVector[2].magnitude
        local Lenght2 = Leg.InitialLegPieceVector[3].magnitude
        local LegOffset = Vector3(2,0,40) -- offset relative to leg orientation (right, up, forward)
        if Leg.FlipX then
            LegOffset.x = -LegOffset.x
        end
        local RollShift = math.sin(ConstructRoll*math.pi/180)*(Lenght1+Lenght2)/4
        RollShift = 0
        local LocalOffset = Vector3(RollShift,0,0) -- offset relative to craft
        local GlobalOffset = Vector3(GlobalLegPosition.x ,-2 ,GlobalLegPosition.z) -- offset in global space
        local LocalTargetPos = Quaternion.Inverse(Leg.IdleRotation) * (InverseCraftRotation * (GlobalOffset - GlobalLegPosition + Leg.IdleRotation * Quaternion.AngleAxis(-ConstructYaw, Vector3.up) * LegOffset) + LocalOffset)
        local Angles = GetLegAngle(LocalTargetPos,Lenght1,Lenght2)
        local alpha = Angles.alpha * 180 / math.pi
        local betha = Angles.betha * 180 / math.pi
        local yaw = Angles.yaw * 180 / math.pi
        local DesiredDirection = Vector3(I:GetConstructForwardVector().x,0,I:GetConstructForwardVector().z).normalized
        if I:GetVelocityVector().magnitude > 35 and false then
            DesiredDirection = Vector3(I:GetVelocityVector().x,0,I:GetVelocityVector().z).normalized 
        end
        local YawRequest = I:GetPropulsionRequest(5)
        local PerfectYawDirection = (I:GetSubConstructInfo(Leg.DefiningSCI).Position - I:GetConstructPosition())

        PerfectYawDirection.y = 0
        PerfectYawDirection = (Quaternion.AngleAxis(90, Vector3.up) * PerfectYawDirection).normalized

        local InterpolDirection = (PerfectYawDirection * YawRequest + DesiredDirection * (1-math.abs(YawRequest))^2).normalized

        if (Lenght1 + Lenght2)*0.95 > math.sqrt(LocalTargetPos.x^2+LocalTargetPos.z^2) and alpha == alpha and betha == betha and yaw == yaw then

            I:SetSpinBlockRotationAngle(Parents[1], yaw) -- yawing entire leg
            I:SetSpinBlockRotationAngle(Parents[2], alpha) -- first segment
            I:SetSpinBlockRotationAngle(Parents[3], betha) -- second segment
            GimbalSpinner(I,Leg.DefiningSCI, Quaternion.FromToRotation(Vector3.forward, InterpolDirection))
        else
            MyLog(I,0,"ERROR:    movement not possible")
        end

    end
end


function Update(I)
    if WSinit == true then
        WaterSkimmerUpdate(I)
    else
        I:ClearLogs()
        InitWaterSkimmer(I)

    end
end


function MyLog(I,priority,message)
    if priority <= DebugLevel then
        I:Log(message)
    end
end 