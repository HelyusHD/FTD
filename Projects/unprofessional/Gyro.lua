-- I save a subconstruct, working as a quick gyro setup, in
-- LUA/gyro


GyroCodeWord ="gyro"


ERROR  = 0  -- shows errors
UPDATE = 20 -- shows the effect of the code
SYSTEM = 30 -- shows the calculations
DebugLevel = UPDATE


-- output LIST: {SubConstructIdentifier1, SubConstructIdentifier2, SubConstructIdentifier3, ...}
-- returns a list of all subconstructs with condition:
-- <CodeWord> is part of CustomName
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
            MyLog(I,ERROR,"ERROR:   SubConstructInfo invalid")
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


-- output LIST: {{SubConstructIdentifier1, {ParentOf1}}, {SubConstructIdentifier2, {ParentOf2}}, ...}
-- dependencies: FindAllSubconstructs(); FindParentsOfSubconstruct()
-- useful combination of FindAllSubconstructs() and FindParentsOfSubconstruct()
-- you can define structures where 1 spinner defines the setup
-- example: animation made out of 3 stacked spinners (name the spinner having no children)
function FindAllStructures(I, CodeWord, Depths)
    local Structures = {}
    local AllSubconstructs = FindAllSubconstructs(I, CodeWord)
    for key, SubConstructIdentifier in pairs(AllSubconstructs) do
        table.insert(Structures, {SubConstructIdentifier = SubConstructIdentifier, Parents = FindParentsOfSubconstruct(I,SubConstructIdentifier, Depths)})
    end
    return Structures
end



function MyLog(I,priority,message)
    if priority <= DebugLevel then
        I:Log(message)
    end
end 



function Update(I)
    for key, Structure in pairs(FindAllStructures(I,GyroCodeWord,4)) do
        I:SetSpinBlockRotationAngle(Structure.SubConstructIdentifier, -I:GetConstructYaw())
        for key, SubConstructIdentifier in pairs(Structure.Parents) do
            local angle = 0
            if key == 2 then
                angle = I:GetConstructPitch()
            end
            if key == 4 then
                angle = -I:GetConstructRoll()
            end
            I:SetSpinBlockRotationAngle(SubConstructIdentifier, angle)
        end
    end
end