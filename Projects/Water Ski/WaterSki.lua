InitTimeInterval = -1 -- how often Init runs again and again | <= 0 disables this feature
InitTimeCounter = 0

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

--||| CLASSES

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

        local CustomName_S6 = I:GetSubConstructInfo(Leg.S6).CustomName
        if string.find(CustomName_S6, "fr") then Leg.DirectionMod = Vector3(1,1,1) end
        if string.find(CustomName_S6, "fl") then Leg.DirectionMod = Vector3(1,1,-1) end
        if string.find(CustomName_S6, "br") then Leg.DirectionMod = Vector3(-1,1,1) end
        if string.find(CustomName_S6, "bl") then Leg.DirectionMod = Vector3(-1,1,-1) end

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
        -- rotates the food of the Leg in global space
        Leg.MoveLeg = function(self,I,pos,rot)
            -- calculating position
            local mod = self.DirectionMod
            local craft_rotation = EulerToMyOwnQuaternion(-I:GetConstructRoll(),I:GetConstructYaw(),-I:GetConstructPitch())
            pos = Vector3(pos.x*mod.x,pos.y*mod.y,pos.z*mod.z)
            local y_shift = (I:GetSubConstructInfo(self.S6).Position + craft_rotation * (Vector3(pos.x,pos.y,pos.z))).y - pos.y
            pos = pos - craft_rotation:Inverse() * Vector3(0,y_shift,0)
            pos = (self.Rotation)*pos - self.Offset
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

        Leg.Rudder = function(self,I,yaw_request)
            if self.rudder_id ~= nil then
                local lever = I:GetSubConstructInfo(self.rudder_id).Position - I:GetConstructCenterOfMass()
                local rot = I:GetSubConstructInfo(self.S1).Rotation
                rot = MyOwnQuaternion.new(rot.w, rot.x, rot.y, rot.z)
                lever = rot:Inverse() * lever
                local best_angle_right = -math.deg(math.atan2(lever.x,lever.z)) + 180
                local best_angle_left = (-math.deg(math.atan2(lever.x,lever.z)) + 90) / 2
                local angle
                if yaw_request >= 0 then
                    if self.DirectionMod.z > 0 then
                        angle = best_angle_right * yaw_request
                    else
                        angle = 0
                    end
                else
                    if self.DirectionMod.z < 0 then
                        angle = -best_angle_left * yaw_request
                    else
                        angle = 0
                    end
                end

                ClearMyLogs(I)
                MyLog(I,SYSTEM,"SYSTEM:   best_angle: "..tostring(angle))
                I:SetSpinBlockRotationAngle(self.rudder_id, angle)
            end
        end

        return Leg
    end

    -- creates a Light_ object
    -- index: its BlockIndex
    -- pos: its local position
    -- Start_pos: the position of the start block of a animation
    function Light_(I,index,pos,Start_pos)
        local Light = {
            index = index,
            order = (pos - Start_pos).magnitude, -- distance to the starting block | used to know the order of lights
            tick = 0, -- counts the ticks burning
            ticks = 0 -- turns off after this many ticks
        }
        -- turns a light on for a amount of ticks
        -- Intensity: [0,10]
        Light.On = function(self,I,Ticks,Intensity)
            self.tick = 0
            self.ticks = Ticks
            I:Component_SetFloatLogic_1(30, self.index, 0, Intensity)
        end

        Light.Off = function(self,I)
            self.tick = 1
            self.ticks = 0
            I:Component_SetFloatLogic_1(30, self.index, 0, 0)
        end

        -- keeps a light ticking to turn it off
        Light.Run = function(self,I)
            if self.tick <= self.ticks then
                self.tick = self.tick + 1
                return false
            else
                I:Component_SetFloatLogic_1(30, self.index, 0, 0)
                return true
            end
        end

        Light.Color = function(self,I,red,green,blue)
            I:Component_SetFloatLogic_3(30, self.index, 2, red, 3, green, 4, blue)
        end

        -- sets the range of the light [1,50]
        Light.Range = function(self,I,Range)
            I:Component_SetFloatLogic_1(30, self.index, 1, Range)
        end

        return Light
    end


    -- creates a LightAnimation_ object based on
    -- the SubConstructIdentifier (the space placed in) and
    -- the Id (a number appearing in the light fitting names)
    -- only the end points need to be named
    function LightAnimation_(I,SubConstructIdentifier,Id)
        local type = 30
        local LA = {
            Start = -1, -- index of start light
            End   = -1, -- index of end light
            Progress = 0,
            TotalDistance = 0, -- ditance from start to end
            Lights = {}, -- list of al lights being part of the animation
            ActiveLights = {}, -- list of updated lights
            ClosestLightLast = {index = -1},
            Valid = false,
            SubConstructIdentifier = SubConstructIdentifier,
            Id = Id,
            PeriodTicks = 100,
            BurnTicks = 10,
            Intensity = 10
        }
        local LightsOnSubConstruct = {}
        for index = 0, I:Component_GetCount(type)-1 do
            local BlockInfo = I:Component_GetBlockInfo(type,index)
            if BlockInfo.SubConstructIdentifier == SubConstructIdentifier then
                table.insert(LightsOnSubConstruct, index)
                if string.find(BlockInfo.CustomName, Id) then
                    if string.find(BlockInfo.CustomName, "start") then LA.Start = index end
                    if string.find(BlockInfo.CustomName, "end") then LA.End = index end
                end
            end
        end

        if LA.Start ~= -1 and LA.End ~= -1 then
            LA.Valid = true
            local Start_pos = I:Component_GetBlockInfo(type,LA.Start).LocalPosition
            local End_Pos = I:Component_GetBlockInfo(type,LA.End).LocalPosition
            LA.TotalDistance = (Start_pos - End_Pos).magnitude
            for _, index in pairs(LightsOnSubConstruct) do
                local pos = I:Component_GetBlockInfo(type,index).LocalPosition
                local distance = DistanceFromPointToLine(pos, Start_pos, End_Pos)
                if distance < 2 then
                    table.insert(LA.Lights, Light_(I,index,pos,Start_pos))
                end
            end
            table.sort(LA.Lights, function(a, b)
                return a.order < b.order
            end)
        else
            MyLog(I,SYSTEM,"SYSTEM:   Animation "..Id.." on SubConstruct"..SubConstructIdentifier.." cant be loaded")
            return LA
        end

        -- Animates a moving light
        -- PeriodTicks: ticks to travel from start to end and
        -- BurnTicks: how long a light stays on
        -- Intensity: [0,10]
        LA.Run = function(self,I)
            local TotalDistance = self.TotalDistance
            local TravelSpeed = TotalDistance/self.PeriodTicks

            if self.Progress <= TotalDistance + TravelSpeed then
                self.Progress = self.Progress + TravelSpeed
            else
                self.Progress = self.Progress + TravelSpeed - TotalDistance
            end

            local ClosestLights = self.Lights
            table.sort(ClosestLights, function(a, b)
                return math.abs(a.order - self.Progress) < math.abs(b.order - self.Progress) and self.Progress > a.order
            end)
            if ClosestLights[1].index ~= self.ClosestLightLast.index then
                if ClosestLights[1].index == self.Start then
                    ClosestLights[1]:On(I,self.BurnTicks/2,self.Intensity)
                    table.insert(self.ActiveLights,ClosestLights[1])
                else
                    ClosestLights[1]:On(I,self.BurnTicks,self.Intensity)
                    table.insert(self.ActiveLights,ClosestLights[1])
                end
            end
            for index, light in pairs(self.ActiveLights) do
                if light:Run(I) then table.remove(self.ActiveLights,index) end
            end
            self.ClosestLightLast = ClosestLights[1]
        end

        -- turn all lights off
        LA.Off = function(self,I)
            for _, light in pairs(self.Lights) do
                light:Off(I)
            end
        end

        LA.Color = function(self,I,red,green,blue)
            for _, light in pairs(self.Lights) do
                light:Color(I,red,green,blue)
            end
        end

        LA.RainbowColors = function(self,I)
            local r, g, b
            for _, light in pairs(self.Lights) do
                local t = light.order/self.TotalDistance
                local i = math.floor(t * 6)
                local f = t * 6 - i
                local q = 1 - f
                if i == 0 then
                    r, g, b = 1, f, 0
                elseif i == 1 then
                    r, g, b = q, 1, 0
                elseif i == 2 then
                    r, g, b = 0, 1, f
                elseif i == 3 then
                    r, g, b = 0, q, 1
                elseif i == 4 then
                    r, g, b = f, 0, 1
                elseif i == 5 then
                    r, g, b = 1, 0, q
                end
                light:Color(I,r,g,b)
            end
        end

        -- sets the range of all lights [1,50]
        LA.Range = function(self,I,Range)
            for _, light in pairs(self.Lights) do
                light:Range(I,Range)
            end
        end
        -- adds a animation to this animation
        LA.Link = function(self,I,Animation,DistanceOfAnimations)
            MyLog(I,SYSTEM,"System:   linking animation")
            if DistanceOfAnimations == nil then
                DistanceOfAnimations = (I:Component_GetBlockInfo(type,self.End).Position - I:Component_GetBlockInfo(type,Animation.Start).Position).magnitude
            end
            local AdditionalLights = Animation.Lights
            for key, Light in pairs(AdditionalLights) do
                -- shifts new lights ahead in order
                AdditionalLights[key].order = AdditionalLights[key].order + DistanceOfAnimations + self.TotalDistance
                -- adds new lights
                table.insert(self.Lights,AdditionalLights[key])
            end
            self.TotalDistance = self.TotalDistance + Animation.TotalDistance + DistanceOfAnimations
            self.End = Animation.End
        end

        LA:Off(I)
        return LA
    end

--||| INITS
    -- creates Leg_ objects for each spinner found named "LEG"
    function Init(I)
        InitLegsDone = true
        InitLightsDone = true
        Legs = {}
        Animations = {}
        ActiveAnimations = {}
        for LegIndex, RootBlock in pairs(FindAllSubconstructs(I, "LEG")) do
            local Limits = {
                S6 = {min = -45, max = 45}, -- extreme angles for S6
                S5 = {min = -50, max = 70}, -- extreme angles for S5
                S4 = {min =  30, max = 180} -- extreme angles for S4
            }

            local RestingPosition = {
                S6 = 0,
                S5 = Limits.S5.max,
                S4 = 30
            }
            local Leg = Leg_(I, RootBlock, Limits, RestingPosition)
            for _, Id in pairs({"01","02"}) do
                local MainAnimation = LightAnimation_(I,Leg.S5,Id)
                local AnimationToAdd = LightAnimation_(I,Leg.S4,Id)
                local DistanceOfAnimations = 5
                MainAnimation:Link(I,AnimationToAdd,DistanceOfAnimations)
                MainAnimation:Range(I,6)
                MainAnimation:RainbowColors(I)
                MainAnimation.PeriodTicks = 80
                MainAnimation.BurnTicks = 4
                MainAnimation.Intensity = 10
                --MainAnimation:Color(I,1,0.5,0)
                table.insert(Animations, MainAnimation)
                table.insert(ActiveAnimations, MainAnimation)
            end
            table.insert(Legs, Leg)
        end
    end

--||| UPDATE

    -- Master function organising / controlling the project
    function WaterSki(I)
        if InitLegsDone ~= true or InitLightsDone ~= true then
            ClearMyLogs(I)
            Init(I)
            local count = 0
            for _, Animation in pairs(Animations) do
                if Animation.Valid then count = count + 1 end
            end
            MyLog(I,SYSTEM,"SYSTEM:   found "..count.." valid light animations")
        else
            InitTimeCounter = InitTimeCounter + 1
            if InitTimeCounter >= InitTimeInterval * 20 and InitTimeInterval > 0 then
                InitTimeCounter = 0
                InitLegsDone = false
                InitLightsDone = false
            end
        -- sends commands to each leg
            for LegIndex, Leg in pairs(Legs) do
                local t = I:GetGameTime()
                local r = 10
                local w = 0
                local pos = Vector3(10,-5,20) + Vector3(math.sin(w*t)*r,0,math.cos(w*t)*r)
                local yaw_command = -I:GetConstructYaw()
                local velocity = I:GetVelocityVector()
                if velocity.magnitude > 5 then 
                    yaw_command = -math.deg(math.atan2(velocity.x,velocity.z))
                end
                local rot = EulerToMyOwnQuaternion(0,yaw_command,0)
                Leg:MoveLeg(I,pos,rot)
                Leg:Rudder(I,I:GetPropulsionRequest(5))
            end

            -- updates / controlls all LightAnimations
            for index, Animation in pairs(ActiveAnimations) do
                if Animation.Valid then
                    local PeriodTicks = 60
                    local BurnTicks = 2
                    local Intensity  = 10
                    Animation:Run(I,PeriodTicks,BurnTicks,Intensity)
                    --Animation:Off(I)
                    --table.remove(ActiveAnimations,index)
                end
            end
        end
    end

    -- is called by the game to update this code
    function Update(I)
        WaterSki(I)
    end
