--||| MATH / USEFUL lib
    ---Enumerations for Logging purposes
    ERROR = 0
    DEBUG = 0.5
    WARNING = 1
    SYSTEM = 2
    UPDATE = 3
    LISTS = 4
    VECTORS = 5
    DebugLevel = SYSTEM

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

    MyOwnQuaternion = {}
    MyOwnQuaternion.__index = MyOwnQuaternion

    -- MyOwnQuaternion constructor
    function MyOwnQuaternion.new(w, x, y, z)
        local self = setmetatable({}, MyOwnQuaternion)
        self.w = w
        self.x = x
        self.y = y
        self.z = z
        self.print= function(self)
            return "MyQuat: "..tostring(x)..","..tostring(y)..","..tostring(z)..","..tostring(w)
        end
        return self
    end

    -- MyOwnQuaternion * MyOwnQuaternion multiplication
    function MyOwnQuaternion:__mul(other)
        if getmetatable(other) == MyOwnQuaternion then
            return MyOwnQuaternion.new(
                self.w * other.w - self.x * other.x - self.y * other.y - self.z * other.z,
                self.w * other.x + self.x * other.w + self.y * other.z - self.z * other.y,
                self.w * other.y - self.x * other.z + self.y * other.w + self.z * other.x,
                self.w * other.z + self.x * other.y - self.y * other.x + self.z * other.w
            )
        elseif type(other) == "table" and other.x and other.y and other.z then
            -- MyOwnQuaternion * Vector3 multiplication
            local num = self.x * 2
            local num2 = self.y * 2
            local num3 = self.z * 2
            local num4 = self.x * num
            local num5 = self.y * num2
            local num6 = self.z * num3
            local num7 = self.x * num2
            local num8 = self.x * num3
            local num9 = self.y * num3
            local num10 = self.w * num
            local num11 = self.w * num2
            local num12 = self.w * num3

            return Vector3(
                (1 - (num5 + num6)) * other.x + (num7 - num12) * other.y + (num8 + num11) * other.z,
                (num7 + num12) * other.x + (1 - (num4 + num6)) * other.y + (num9 - num10) * other.z,
                (num8 - num11) * other.x + (num9 + num10) * other.y + (1 - (num4 + num5)) * other.z
            )
        else

        end
    end

    -- Calculate the inverse of the quaternion
    function MyOwnQuaternion:Inverse()
        local norm = self.w * self.w + self.x * self.x + self.y * self.y + self.z * self.z
        return MyOwnQuaternion.new(self.w / norm, -self.x / norm, -self.y / norm, -self.z / norm)
    end

    function quaternionToEuler(quaternion)
        -- Extract the quaternion components
        local x = quaternion.y
        local y = quaternion.x
        local z = quaternion.z
        local w = quaternion.w

        -- Calculate the Euler angles from the quaternion
        local ysqr = y * y

        -- Roll (x-axis rotation)
        local t0 = 2 * (w * x + y * z)
        local t1 = 1 - 2 * (x * x + ysqr)
        local roll = math.atan2(t0, t1)

        -- Pitch (y-axis rotation)
        local t2 = 2 * (w * y - z * x)
        if t2 > 1 then t2 = 1 end
        if t2 < -1 then t2 = -1 end
        local pitch = math.asin(t2)

        -- Yaw (z-axis rotation)
        local t3 = 2 * (w * z + x * y)
        local t4 = 1 - 2 * (ysqr + z * z)
        local yaw = math.atan2(t3, t4)

        -- Convert from radians to degrees
        roll = roll * 180 / math.pi
        pitch = pitch * 180 / math.pi
        yaw = yaw * 180 / math.pi

        return Vector3(pitch, roll, yaw)
    end

    -- Function to convert Euler angles (in degrees) to quaternion
    -- Input: Three Euler angles (in degrees) representing rotations around X, Y, and Z axis
    -- Output: Corresponding quaternion
    -- FTDs implementation of Quaternion.Euler() is not working correctly from time to time, so I have to use this
    function EulerToMyOwnQuaternion(degreesX, degreesY, degreesZ)
        -- Convert degrees to radians
        local rx = math.rad(degreesZ)
        local ry = math.rad(degreesX)
        local rz = math.rad(degreesY)

        local qx = math.cos(rx / 2) * math.sin(ry / 2) * math.cos(rz / 2) + math.sin(rx / 2) * math.cos(ry / 2) * math.sin(rz / 2)
        local qy = math.cos(rx / 2) * math.cos(ry / 2) * math.sin(rz / 2) - math.sin(rx / 2) * math.sin(ry / 2) * math.cos(rz / 2)
        local qz = math.sin(rx / 2) * math.cos(ry / 2) * math.cos(rz / 2) - math.cos(rx / 2) * math.sin(ry / 2) * math.sin(rz / 2)
        local qw = math.cos(rx / 2) * math.cos(ry / 2) * math.cos(rz / 2) + math.sin(rx / 2) * math.sin(ry / 2) * math.sin(rz / 2)

        return MyOwnQuaternion.new(qw,qx,qy,qz)
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

    -- calculates the perpendicular distance from a point to a line defined by two points in 3D space.
    function DistanceFromPointToLine(point, linePoint1, linePoint2)
        local lineDirection = linePoint2 - linePoint1 
        local distance = Vector3.Cross(lineDirection, point - linePoint1).magnitude / lineDirection.magnitude
        return distance
    end    
--||| CLASS Leg_
    -- creates a Leg_ object based on the RootBlock spinner (the spinner no other spinners are placed on)
    function Leg_(I, RootBlock, Limits, RestingPosition)
        local Leg = {
            Limits = {
                S6 = {min = Limits.S6.min, max = Limits.S6.max}, -- extreme angles for S6
                S5 = {min = Limits.S5.min, max = Limits.S5.max}, -- extreme angles for S5
                S4 = {min = Limits.S4.min, max = Limits.S4.max}  -- extreme angles for S4
            },
            RestingPosition = {
                S6 = RestingPosition.S6,
                S5 = RestingPosition.S5,
                S4 = RestingPosition.S4
            },
        }
        -- Sn are the joints of a leg where the biggest n is the spinner placed on the craft
        Leg.S1 = RootBlock
        Leg.S2 = I:GetParent(I:GetParent(Leg.S1))
        Leg.S3 = I:GetParent(I:GetParent(Leg.S2))
        Leg.S4 = I:GetParent(Leg.S3)
        Leg.S5 = I:GetParent(Leg.S4)
        Leg.S6 = I:GetParent(Leg.S5)
        Leg.Rotation = I:GetSubConstructIdleRotation(Leg.S6)
        Leg.Rotation = MyOwnQuaternion.new(Leg.Rotation.w,Leg.Rotation.x,Leg.Rotation.y,Leg.Rotation.z)
        Leg.UpperLeg = (I:GetSubConstructInfo(Leg.S4).Position - I:GetSubConstructInfo(Leg.S5).Position).magnitude
        Leg.LowerLeg = (I:GetSubConstructInfo(Leg.S3).Position - I:GetSubConstructInfo(Leg.S4).Position).magnitude
        Leg.SpinnerShift = (I:GetSubConstructInfo(Leg.S2).Position - I:GetSubConstructInfo(Leg.S3).Position).magnitude
        local rot_S6 = I:GetSubConstructInfo(Leg.S6).Rotation
        Leg.Offset = MyOwnQuaternion.new(rot_S6.w,rot_S6.x,rot_S6.y,rot_S6.z):Inverse() * (I:GetSubConstructInfo(Leg.S5).Position - I:GetSubConstructInfo(Leg.S6).Position)
        local IdleRotation = I:GetSubConstructIdleRotation(Leg.S6)
        Leg.RotOffset = MyOwnQuaternion.new(IdleRotation.w,IdleRotation.x,IdleRotation.y,IdleRotation.z)

        -- used to define the general position of the leg on the craft
        local CustomName_S6 = I:GetSubConstructInfo(Leg.S6).CustomName
        if string.find(CustomName_S6, "fr") then Leg.DirectionMod = Vector3(1,1,-1) end
        if string.find(CustomName_S6, "fl") then Leg.DirectionMod = Vector3(-1,1,1) end
        if string.find(CustomName_S6, "br") then Leg.DirectionMod = Vector3(1,1,-1) end
        if string.find(CustomName_S6, "bl") then Leg.DirectionMod = Vector3(-1,1,1) end

        Leg.Debug = false
        if string.find(CustomName_S6, "debug") then Leg.Debug = true end

        if Leg.DirectionMod == nil then 
            InitLegsDone = false
            MyLog(I,ERROR,"ERROR:   A leg has no assigned direction. You have to name the 1. parent spinner.")
        end

        for index = 0 , I:GetSubconstructsChildrenCount(Leg.S1)-1 do
            local rudder_id = I:GetSubConstructChildIdentifier(Leg.S1, index)
            if string.find(I:GetSubConstructInfo(rudder_id).CustomName,"rudder") then
                Leg.rudder_id = rudder_id
            end
        end

        -- moves a Leg to a position (x,y,z) where x and z are in craft space and y in global space
        -- rotates the foot of the Leg in global space
        --[[Leg.MoveLeg = function(self,I,pos,rot)
            -- calculating position
            local mod = self.DirectionMod
            local craft_rotation = EulerToMyOwnQuaternion(-I:GetConstructRoll(),I:GetConstructYaw(),-I:GetConstructPitch())
            pos = Vector3(pos.x*mod.x,pos.y*mod.y,pos.z*mod.z)
            -- pos will change if the craft rolls or pitches
            local rotation_displacement = Vector3(0, (I:GetSubConstructInfo(self.S6).Position + craft_rotation * pos).y - pos.y, 0)
            pos = pos - craft_rotation:Inverse() * rotation_displacement
            pos = (self.Rotation)*pos - self.Offset
            -- making sure the foot wont be under ground
            local local_pos = I:GetSubConstructInfo(self.S6).LocalPosition + pos
            local global_pos = I:GetSubConstructInfo(self.S6).Position + craft_rotation * pos
            local TerrainAltitude = I:GetTerrainAltitudeForLocalPosition(local_pos.x,local_pos.y,local_pos.z)
            local FootOffset = 1.5
            if global_pos.y + FootOffset < TerrainAltitude then
                global_pos.y = TerrainAltitude - FootOffset
                pos = craft_rotation:Inverse() * (global_pos - I:GetSubConstructInfo(self.S6).Position)
            end

            -- positioning
            local r = pos.magnitude
            local a = self.UpperLeg
            local b = self.LowerLeg + self.SpinnerShift
            local alpha, betha, gamma

            if math.abs((a^2+r^2-b^2)/(2*a*r))<=1 then
                alpha = math.deg(math.atan2(pos.z,pos.x))
                betha = math.deg(math.acos((a^2+r^2-b^2)/(2*a*r)) + math.asin(pos.y/r))
                gamma = math.deg(math.acos((a^2+b^2-r^2)/(2*a*b)))

                alpha = math.min(alpha,self.Limits.S6.max); alpha = math.max(alpha,self.Limits.S6.min)
                betha = math.min(betha,self.Limits.S5.max); betha = math.max(betha,self.Limits.S5.min)
                gamma = math.min(gamma,self.Limits.S4.max); gamma = math.max(gamma,self.Limits.S4.min)
            else
                alpha =  self.RestingPosition.S6
                betha =  self.RestingPosition.S5
                gamma =  self.RestingPosition.S4
            end
            I:SetSpinBlockRotationAngle(self.S6, alpha)
            I:SetSpinBlockRotationAngle(self.S5, -betha)
            I:SetSpinBlockRotationAngle(self.S4, -gamma-180)

            --rotating
            local a = (I:GetSubConstructInfo(self.S4).Rotation)
            a = MyOwnQuaternion.new(a.w,a.x,a.y,a.z)
            local euler = quaternionToEuler(rot * (a))


            I:SetSpinBlockRotationAngle(self.S3, -euler.z)
            I:SetSpinBlockRotationAngle(self.S2, -euler.x)
            I:SetSpinBlockRotationAngle(self.S1, -euler.y)
        end
        --]]

        Leg.MoveLeg = function(self,I,global_pos,rot)
            local global_pos2 = I:GetConstructPosition()
            -- calculating position in leg space
            local craft_rotation = EulerToMyOwnQuaternion(-I:GetConstructRoll(),I:GetConstructYaw(),-I:GetConstructPitch())
            local pos = craft_rotation:Inverse() * (global_pos2 - I:GetSubConstructInfo(self.S6).Position)
            pos = Leg:Modifier(pos)

            -- positioning
            local r = pos.magnitude
            local a = self.UpperLeg
            local b = self.LowerLeg + self.SpinnerShift
            local alpha, betha, gamma

            if math.abs((a^2+r^2-b^2)/(2*a*r))<=1 then
                alpha = math.deg(math.atan2(pos.z,pos.x))
                betha = math.deg(math.acos((a^2+r^2-b^2)/(2*a*r)) + math.asin(pos.y/r))
                gamma = math.deg(math.acos((a^2+b^2-r^2)/(2*a*b)))

                alpha = math.min(alpha,self.Limits.S6.max); alpha = math.max(alpha,self.Limits.S6.min)
                betha = math.min(betha,self.Limits.S5.max); betha = math.max(betha,self.Limits.S5.min)
                gamma = math.min(gamma,self.Limits.S4.max); gamma = math.max(gamma,self.Limits.S4.min)
            else
                alpha =  self.RestingPosition.S6
                betha =  self.RestingPosition.S5
                gamma =  self.RestingPosition.S4
            end
            I:SetSpinBlockRotationAngle(self.S6, alpha)
            I:SetSpinBlockRotationAngle(self.S5, -betha)
            I:SetSpinBlockRotationAngle(self.S4, -gamma-180)

            --rotating
            local a = (I:GetSubConstructInfo(self.S4).Rotation)
            a = MyOwnQuaternion.new(a.w,a.x,a.y,a.z)
            local euler = quaternionToEuler(rot * (a))


            I:SetSpinBlockRotationAngle(self.S3, -euler.z)
            I:SetSpinBlockRotationAngle(self.S2, -euler.x)
            I:SetSpinBlockRotationAngle(self.S1, -euler.y)
        end

        -- applies the DirectionMod to a position
        -- we do this because a right side leg behaves different than a left side leg
        Leg.Modifier = function(self,pos)
            local mod = self.DirectionMod
            return Vector3(pos.x*mod.x,pos.y*mod.y,pos.z*mod.z)
        end

        -- turns a local (craft space) position into a global one
        Leg.Local_to_global = function(self,I,local_pos)
            local craft_rotation = EulerToMyOwnQuaternion(-I:GetConstructRoll(),I:GetConstructYaw(),-I:GetConstructPitch())
            return I:GetConstructPosition() + craft_rotation * local_pos
        end

        return Leg
    end

--||| INIT
    function SpiderWalkerInit(I)
        SpiderWalkerInitDone = true
        local SpiderLegs = {}
        --[[
        local Limits = {
            S6 = {min = -45, max = 45}, -- extreme angles for S6
            S5 = {min = -50, max = 70}, -- extreme angles for S5
            S4 = {min =  30, max = 180} -- extreme angles for S4
        }
        --]]
        local Limits = {
            S6 = {min = -180, max = 180}, -- extreme angles for S6
            S5 = {min = -180, max = 180}, -- extreme angles for S5
            S4 = {min = -180, max = 180} -- extreme angles for S4
        }
        local RestingPosition = {
            S6 = 0,
            S5 = Limits.S5.max,
            S4 = 30
        }
        for LegIndex, RootBlock in pairs(FindAllSubconstructs(I, "LEG")) do
            local Leg = Leg_(I, RootBlock, Limits, RestingPosition)
            table.insert(SpiderLegs, Leg)
        end
        return SpiderLegs
    end
--||| UPDATE
    function SpiderWalker(I)
        if SpiderWalkerInitDone ~= true then
            SpiderLegs = SpiderWalkerInit(I)
        else
            local t = I:GetGameTime()
            local r = 10
            local w = 0
            local pos = Vector3(0,0,30) + Vector3(math.sin(w*t)*r,0,math.cos(w*t)*r*0)
            for _, Leg in pairs(SpiderLegs)do
                local yaw_command = -I:GetConstructYaw()
                local pos = Vector3(0,0,0)
                pos = Leg:Local_to_global(I,pos)
                local rot = EulerToMyOwnQuaternion(0,yaw_command,0)
                Leg:MoveLeg(I,pos,rot)
            end
        end
    end

    function Update(I)
        SpiderWalker(I)
    end