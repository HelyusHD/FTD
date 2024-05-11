    ---Enumerations for Logging purposes
    ERROR = 0
    WARNING = 1
    SYSTEM = 2
    UPDATE = 3
    LISTS = 4
    VECTORS = 5
    DebugLevel = SYSTEM


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
    Leg.S4 = I:GetParent(Leg.S3)
    Leg.S5 = I:GetParent(Leg.S4)
    Leg.S6 = I:GetParent(Leg.S5)
    Leg.Rotation = I:GetSubConstructIdleRotation(Leg.S6)
    Leg.UpperLeg = (I:GetSubConstructInfo(Leg.S4).Position - I:GetSubConstructInfo(Leg.S5).Position).magnitude
    Leg.LowerLeg = (I:GetSubConstructInfo(Leg.S3).Position - I:GetSubConstructInfo(Leg.S4).Position).magnitude
    Leg.Offset = I:GetSubConstructInfo(Leg.S5).Position - I:GetSubConstructInfo(Leg.S6).Position
    local CustomName_S6 = I:GetSubConstructInfo(Leg.S6).CustomName
    if string.find(CustomName_S6, "fr") then Leg.DirectionMod = Vector3(1,1,1) end
    if string.find(CustomName_S6, "fl") then Leg.DirectionMod = Vector3(1,1,-1) end
    if string.find(CustomName_S6, "br") then Leg.DirectionMod = Vector3(-1,1,1) end
    if string.find(CustomName_S6, "bl") then Leg.DirectionMod = Vector3(-1,1,-1) end

    if Leg.DirectionMod == nil then 
        InitLegsDone = false
        MyLog(I,ERROR,"ERROR:   A leg has no assigned direction. You have to name the 1. parent spinner.")
    end
    return Leg
end



function MoveLeg(I,Leg,pos,rot)
    -- calculating position
    local mod = Leg.DirectionMod
    local craft_rotation = Quaternion.Euler(-I:GetConstructRoll(),I:GetConstructYaw(),-I:GetConstructPitch())
    pos = Vector3(pos.x*mod.x,pos.y*mod.y,pos.z*mod.z)
    local y_shift = (I:GetSubConstructInfo(Leg.S6).Position + craft_rotation * (Vector3(pos.x,pos.y,pos.z))).y - pos.y
    pos = pos - Quaternion.Inverse(craft_rotation) * Vector3(0,y_shift,0)
    pos = ((Leg.Rotation)*pos) - Leg.Offset
    -- positioning
    local r = pos.magnitude
    local a = Leg.UpperLeg
    local b = Leg.LowerLeg
    local alpha = math.deg(math.atan2(pos.z,pos.x))
    local betha = math.deg(math.acos((a^2+r^2-b^2)/(2*a*r)) + math.asin(pos.y/r))
    local gamma = math.deg(math.acos((a^2+b^2-r^2)/(2*a*b)))
    I:SetSpinBlockRotationAngle(Leg.S6, alpha)
    I:SetSpinBlockRotationAngle(Leg.S5, -betha)
    I:SetSpinBlockRotationAngle(Leg.S4, -gamma-180)

    --rotating
    local a = (I:GetSubConstructInfo(Leg.S4).Rotation)
    local euler = (rot * (a)).eulerAngles
    I:SetSpinBlockRotationAngle(Leg.S3, -euler.z)
    I:SetSpinBlockRotationAngle(Leg.S2, -euler.x)
    I:SetSpinBlockRotationAngle(Leg.S1, -euler.y)
end

function InitLegs(I)
    InitLegsDone = true
    local Legs = {}
    for LegIndex, RootBlock in pairs(FindAllSubconstructs(I, "LEG")) do
        table.insert(Legs, Leg_(I, RootBlock))
    end
    return Legs
end

function WaterSkiUpdate(I)
    local t = I:GetGameTime()
    local w = 0
    local r = 180
    local pos = Vector3(40,0,20)
    for LegIndex, Leg in pairs(Legs) do
        local yaw_command = I:GetPropulsionRequest(5) * Leg.DirectionMod.x * 45
        local rot = Quaternion.Euler(0,-I:GetConstructYaw(),0)
        MoveLeg(I,Leg,pos,rot)
    end
end

function WaterSki(I)
    if InitLegsDone ~= true then
        ClearMyLogs(I)
        Legs = InitLegs(I)
    else
        WaterSkiUpdate(I)
    end
end

function Update(I)
    WaterSki(I)
end

FinalMessage = ""
function MyLog(I,priority,Message)
    if priority <= DebugLevel then
        if FinalMessage == "" then
            FinalMessage = Message
        else
            FinalMessage = FinalMessage.."\n"..Message
        end
        I:ClearLogs()
        I:Log(FinalMessage)
    end
end
function ClearMyLogs(I)
    FinalMessage = ""
    I:ClearLogs()
end