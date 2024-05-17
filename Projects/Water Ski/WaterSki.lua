    ---Enumerations for Logging purposes
    ERROR = 0
    WARNING = 1
    SYSTEM = 2
    UPDATE = 3
    LISTS = 4
    VECTORS = 5
    DebugLevel = SYSTEM


-- Function to convert Euler angles (in degrees) to quaternion
-- Input: Three Euler angles (in degrees) representing rotations around X, Y, and Z axis
-- Output: Corresponding quaternion
-- FTDs implementation of Quaternion.Euler() is not working correctly from time to time, so I have to use this
function EulerToQuaternion(degreesX, degreesY, degreesZ)
    -- Convert degrees to radians
    local rx = math.rad(degreesZ)
    local ry = math.rad(degreesX)
    local rz = math.rad(degreesY)

    local qx = math.cos(rx / 2) * math.sin(ry / 2) * math.cos(rz / 2) + math.sin(rx / 2) * math.cos(ry / 2) * math.sin(rz / 2)
    local qy = math.cos(rx / 2) * math.cos(ry / 2) * math.sin(rz / 2) - math.sin(rx / 2) * math.sin(ry / 2) * math.cos(rz / 2)
    local qz = math.sin(rx / 2) * math.cos(ry / 2) * math.cos(rz / 2) - math.cos(rx / 2) * math.sin(ry / 2) * math.sin(rz / 2)
    local qw = math.cos(rx / 2) * math.cos(ry / 2) * math.cos(rz / 2) + math.sin(rx / 2) * math.sin(ry / 2) * math.sin(rz / 2)
    
    return Quaternion(qx,qy,qz,qw)
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

-- creates a Leg_ object based on the RootBlock spinner (the spinner no other spinners are placed on)
function Leg_(I, RootBlock)
    local Leg = {}
    -- Sn are the joints of a leg where the biggest n is the spinner placed on the craft
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
    -- moves a Leg to a position (x,y,z) where x and z are in craft space and y in global space
    -- rotates the food of the Leg in global space
    Leg.MoveLeg = function(self,I,pos,rot)
        -- calculating position
        local mod = self.DirectionMod
        local craft_rotation = EulerToQuaternion(-I:GetConstructRoll(),I:GetConstructYaw(),-I:GetConstructPitch())
        pos = Vector3(pos.x*mod.x,pos.y*mod.y,pos.z*mod.z)
        local y_shift = (I:GetSubConstructInfo(self.S6).Position + craft_rotation * (Vector3(pos.x,pos.y,pos.z))).y - pos.y
        pos = pos - Quaternion.Inverse(craft_rotation) * Vector3(0,y_shift,0)
        pos = ((self.Rotation)*pos) - self.Offset
        -- positioning
        local r = pos.magnitude
        local a = self.UpperLeg
        local b = self.LowerLeg
        if math.abs((a^2+r^2-b^2)/(2*a*r))<=1 then
            local betha = math.deg(math.acos((a^2+r^2-b^2)/(2*a*r)) + math.asin(pos.y/r))
            local gamma = math.deg(math.acos((a^2+b^2-r^2)/(2*a*b)))
            local alpha = math.deg(math.atan2(pos.z,pos.x))
            I:SetSpinBlockRotationAngle(self.S6, alpha)
            I:SetSpinBlockRotationAngle(self.S5, -betha)
            I:SetSpinBlockRotationAngle(self.S4, -gamma-180)
        end

        --rotating
        local a = (I:GetSubConstructInfo(self.S4).Rotation)
        local euler = (rot * (a)).eulerAngles
        I:SetSpinBlockRotationAngle(self.S3, -euler.z)
        I:SetSpinBlockRotationAngle(self.S2, -euler.x)
        I:SetSpinBlockRotationAngle(self.S1, -euler.y)
    end
    return Leg
end


-- creates Leg_ objects for each spinner found named "LEG"
function InitLegs(I)
    InitLegsDone = true
    local Legs = {}
    for LegIndex, RootBlock in pairs(FindAllSubconstructs(I, "LEG")) do
        table.insert(Legs, Leg_(I, RootBlock))
    end
    return Legs
end

-- sends commands to each leg
function WaterSkiUpdate(I)
    for LegIndex, Leg in pairs(Legs) do
        local pos = Vector3(40,-5,20)
        local yaw_command = -I:GetConstructYaw() - I:GetPropulsionRequest(5) * Leg.DirectionMod.x * 45
        local velocity = I:GetVelocityVector()
        local velocity_command = (1 - math.abs(I:GetPropulsionRequest(5)))*(-math.deg(math.atan2(velocity.x,velocity.z)))
        --local rot = EulerToQuaternion(0,yaw_command + velocity_command,0)
        local rot = EulerToQuaternion(0,yaw_command,0)
        Leg:MoveLeg(I,pos,rot)
    end
end

-- controlls legs to keep hydrofoils at the desired position
function WaterSki(I)
    if InitLegsDone ~= true then
        ClearMyLogs(I)
        Legs = InitLegs(I)
    else
        WaterSkiUpdate(I)
    end
end

-- a better log function
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

function Update(I)
    WaterSki(I)
end