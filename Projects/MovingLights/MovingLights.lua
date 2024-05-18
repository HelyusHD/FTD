    ---Enumerations for Logging purposes
    ERROR = 0
    WARNING = 1
    SYSTEM = 2
    UPDATE = 3
    LISTS = 4
    VECTORS = 5
    DebugLevel = SYSTEM

-- calculates the perpendicular distance from a point to a line defined by two points in 3D space.
function DistanceFromPointToLine(point, linePoint1, linePoint2)
    local lineDirection = linePoint2 - linePoint1 
    local distance = Vector3.Cross(lineDirection, point - linePoint1).magnitude / lineDirection.magnitude
    return distance
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
    Light.Update = function(self,I)
        if self.tick <= self.ticks then
            self.tick = self.tick + 1
        else
            I:Component_SetFloatLogic_1(30, self.index, 0, 0)
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
        Start = -1,
        End   = -1,
        Progress = 0,
        TotalDistance = 0, -- ditance from start to end
        Lights = {},
        ClosestLightLast = {index = -1}
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
        return nil
    end

    -- Animates a moving light
    -- PeriodTicks: ticks to travel from start to end and
    -- BurnTicks: how long a light stays on
    -- Intensity: [0,10]
    LA.Run = function(self,I,PeriodTicks,BurnTicks,Intensity)
        local TotalDistance = self.TotalDistance
        local TravelSpeed = TotalDistance/PeriodTicks

        if self.Progress <= TotalDistance + TravelSpeed then
            self.Progress = self.Progress + TravelSpeed
        else
            self.Progress = self.Progress + TravelSpeed - TotalDistance
        end

        local ClosestLights = self.Lights
        table.sort(ClosestLights, function(a, b)
            return math.abs(a.order - self.Progress) < math.abs(b.order - self.Progress)
        end)
        if ClosestLights[1].index ~= self.ClosestLightLast.index then
            if ClosestLights[1].index == self.Start then
                ClosestLights[1]:On(I,BurnTicks/2,Intensity)
            else
                ClosestLights[1]:On(I,BurnTicks,Intensity)
            end
        end
        for _, light in pairs(self.Lights) do
            light:Update(I)
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

    -- sets the range of all lights [1,50]
    LA.Range = function(self,I,Range)
        for _, light in pairs(self.Lights) do
            light:Range(I,Range)
        end
    end

    return LA
end

-- finds all LightAnimations
function InitLights(I)
    InitLightsDone = true
    local Animations = {}
    local SubConstructIdentifier = 0
    local Id = "01"
    local Animation_01 = LightAnimation_(I,SubConstructIdentifier,Id)
    MyLog(I,SYSTEM,"SYSTEM:   Animation_01 has "..tostring(#Animation_01.Lights).." lights")
    table.insert(Animations,Animation_01)
    return Animations
end

-- updates / controlls all LightAnimations
function UpdateLights(I)
    for _, Animation in pairs(Animations) do
        --Animation:Off(I)
        local PeriodTicks = 80
        local BurnTicks = 4
        local Intensity  = 10
        Animation:Range(I,1)
        Animation:Color(I,1,0,0)
        Animation:Run(I,PeriodTicks,BurnTicks,Intensity)
    end
end

-- master function
function LightAnimations(I)
    if InitLightsDone ~= true then
        Animations = InitLights(I)
        MyLog(I,SYSTEM,"SYSTEM:   found "..tostring(#Animations).." light animations")
    else
        UpdateLights(I)
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

-- is called by the game to update this code
function Update(I)
    LightAnimations(I)
end