--||| MANUAL
    --[[
    Thx for using my code!
    There are three different sets of settings you have to understand in order to use this code correctly.
    The FIRST set will define what lmaps should be used in a specific animation.
    The SECOND set is responsible for telling the lamps what to do.
        For example how bright they should be or for how long they should burn
    The THIRD set will define when the animation should be running.

    You can only add lamps to a animation, that are placed on the same SubConstruct.
    The first setting SubConName will attempt to create a animation on each subconstruct named that way.
    If your lights are placed on the craft itself and not on a spinner or smth like that, you can use "CRAFT" to refer to the craft itself.
    Because there may be multiple animations in the same construct space, you have to give each animation its own Identifier.

    There are code words you can use to link lamps to a system.
    Each lamp WITH A CODE WORD has to contain the Identifier as well.
        "start" and "end" can be used to link all lamps in between a starting and a end point.

    You can link 2 animations together. This will cause the second animation to start once the first one is finished.
        All animations with the same LinkId will be chained going from top to bottom.
        You can add the Distance (in blocks) to a linked animation.
        This will cause it to delay its start by the time it would take the animation to travel this distance.
        If you set it to -1, the delay will be calculated based on the real distance between the animations.
        The master animation, all animations get linked to, may have a LoopOffset,
        which is a delay (in blocks) for the animation to start all over again after it is finished.

    Now that you know how to tell the system what lmaps to use, lets talk about how those lamps will actually behave.
    Maybe you niticed the setting "AniationName". This setting is responsible for telling the selected lamps what animation to use.
        PeriodTicks is the time in ticks (40 ticks = 1 second) it should take a animaion to finishe.
        BurnTicks is the time each lamp will stay turned on.
        Intensity is the brightness of the lamps.
        Color are the RGB (red green blue) settings for the lamps.
    ]]

--||| SETTINGS
    GeneralSettings = {
    --  SubConName      Identifier  AnimationName   LinkId  Distance    LoopOffset
        {"CRAFT",       "01",       "Animation_01", "1",    0,         10},
        {"CRAFT",       "02",       "Animation_01", "1",    -1,         0}
    }

    AnimationSettings = {
    --  PeriodTicks BurnTicks   Intensity   Range   AnimationName       Color
        {80,        7,          10,         2,     "Animation_01",     {1,0,0}}
    }

    ControllSettings = {
    --  AnimationName   controll
        {"Animation_01","test 01"}
    }

--||| Math/Useful lib
    ---Enumerations for Logging purposes
        ERROR = 0
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

    -- calculates the perpendicular distance from a point to a line defined by two points in 3D space.
    function DistanceFromPointToLine(point, linePoint1, linePoint2)
        local lineDirection = linePoint2 - linePoint1 
        local distance = Vector3.Cross(lineDirection, point - linePoint1).magnitude / lineDirection.magnitude
        return distance
    end

    -- output LIST: {SubConstructIdentifier1, SubConstructIdentifier2, SubConstructIdentifier3, ...}
    -- returns a list of all subconstructs with condition:
    -- <CodeWord> is part of CustomName
    function FindAllSubconstructs(I, CodeWord)
        -- can return the id of the craft itself, which is always 0
        if CodeWord == "CRAFT" then return {0} end

        local ChosenSubconstructs = {}
        local SubconstructsCount = I:GetAllSubconstructsCount()
        for index = 0, SubconstructsCount-1 do
            local SubConstructIdentifier = I:GetSubConstructIdentifier(index)
            if I:GetSubConstructInfo(SubConstructIdentifier).Valid then
                if string.find(I:GetSubConstructInfo(SubConstructIdentifier).CustomName, CodeWord) then
                    table.insert(ChosenSubconstructs, SubConstructIdentifier)
                end
            else
                --ERROR
            end
        end
        return ChosenSubconstructs
    end

--||| CLASSES
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

        -- changes the color of a light
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
    -- the general idea is, that I am moving a point through space which turns on close lights for a fixed duration
    function LightAnimation_(I,SubConstructIdentifier,Id)
        local type = 30 -- the component type used by some in game funktions
        local LA = {
            AnimationId = -1, -- the Id of the animation / the key in the list Animations
            Start = -1, -- index of start light
            End   = -1, -- index of end light
            Progress = 0, -- [0,TotalDistance] an animation runs from 0m to TotalDistance. then it repeats
            TotalDistance = 0, -- ditance from start to end
            Lights = {}, -- list of al lights being part of the animation
            ActiveLights = {}, -- list of updated lights
            ClosestLightLast = {index = -1},
            Valid = false,
            SubConstructIdentifier = SubConstructIdentifier,
            Id = Id,
            PeriodTicks = 100,
            BurnTicks = 10,
            Intensity = 10,
            Range = 10,
            LoopOffset = 0, -- fixes the jump from the end lamp to the first lamp by setting the progress to < 0
            LinkId = nil, -- used to link animations
            DistanceOfAnimations = -1, -- used to add delay between linked animations
            controll_channel = "", -- name of a custom channel that can be used to run the animation
            running = false
        }
        -- loading end point lights
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
        -- loading lights between end points if end points could be loaded
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
            MyLog(I,SYSTEM,"SYSTEM:   Animation "..Id.." on SubConstruct "..SubConstructIdentifier.." cant be loaded")
            return LA
        end

        -- Animates a moving light
        -- PeriodTicks: ticks to travel from start to end and
        -- BurnTicks: how long a light stays on
        -- Intensity: [0,10]
        LA.Run = function(self,I,Id)
            local LoopOffset = self.LoopOffset
            local TotalDistance = self.TotalDistance
            local TravelSpeed = TotalDistance/self.PeriodTicks

            -- loops the animation once 
            if self.Progress <= TotalDistance + TravelSpeed then
                self.Progress = self.Progress + TravelSpeed
            else
                self.Progress = self.Progress + TravelSpeed - TotalDistance - LoopOffset
            end

            local ClosestLights = self.Lights
            table.sort(ClosestLights, function(a, b)
                return math.abs(a.order - self.Progress) < math.abs(b.order - self.Progress) and self.Progress > a.order
            end)
            if ClosestLights[1].index ~= self.ClosestLightLast.index then
                if ClosestLights[1].index == self.Start then
                    ClosestLights[1]:On(I,self.BurnTicks,self.Intensity)
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

        -- turns all lights off
        LA.Off = function(self,I)
            for _, light in pairs(self.Lights) do
                light:Off(I)
            end
        end

        -- changes the color of all lights
        LA.Color = function(self,I,red,green,blue)
            for _, light in pairs(self.Lights) do
                light:Color(I,red,green,blue)
            end
        end

        -- changes the color of all lights
        -- speed: the rainbow itself will move. This setting is the period time.
        LA.RainbowColors = function(self,I,speed)
            local r, g, b
            
            local shift = 0
            if speed ~= nil and speed ~= 0 then
                shift = I:GetGameTime() % speed / speed
            end
            
            for _, light in pairs(self.Lights) do
                local t = light.order/self.TotalDistance + shift
                t = t % 1
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
        LA.SetRange = function(self,I)
            for _, light in pairs(self.Lights) do
                light:Range(I,self.Range)
            end
        end
        -- adds a animation to this animation
        LA.Link = function(self,I,Animation)
            MyLog(I,SYSTEM,"System:   linking animation")
            if Animation.DistanceOfAnimations == -1 then
                Animation.DistanceOfAnimations = (I:Component_GetBlockInfo(type,self.End).Position - I:Component_GetBlockInfo(type,Animation.Start).Position).magnitude
            end
            local AdditionalLights = Animation.Lights
            for key, Light in pairs(AdditionalLights) do
                -- shifts new lights ahead in order
                AdditionalLights[key].order = AdditionalLights[key].order + Animation.DistanceOfAnimations + self.TotalDistance
                -- adds new lights
                table.insert(self.Lights,AdditionalLights[key])
            end
            self.TotalDistance = self.TotalDistance + Animation.TotalDistance + Animation.DistanceOfAnimations
            self.End = Animation.End
        end

        -- starts and stops the animation
        LA.ControllStart = function(self,I,Id)
            local drive = I:GetCustomAxis(self.controll_channel)
            MyLog(I,SYSTEM,"SYSTEM:   running: "..tostring(self.running).." drive: "..tostring(drive))
            if drive == 1 and not self.running then
                MyLog(I,SYSTEM,"SYSTEM:   Now animating animation: "..Id)
                self.running = true
                -- copies the animation into an updated list that keeps it running.
                table.insert(ActiveAnimations,self)
            end
        end
        LA.ControllEnd = function(self,I,Id)
            local drive = I:GetCustomAxis(self.controll_channel)
            if drive == 0 then
                LA:Off(I)
                Animations[self.AnimationId].running = false
                ActiveAnimations[Id] = nil
            end
        end

        LA:Off(I)
        return LA
    end

--||| INIT
    -- creates the LightAnimations
    function InitLights(I)
        InitLightsDone = true
        local Animations = {}
        ActiveAnimations = {}
        for _, GeneralSetting in pairs(GeneralSettings) do
            -- loading animations from settings
            for _, AnimationSetting in pairs(AnimationSettings) do
                local matched_AnimationSetting = false
                local matched_SubconstructName = false
                local matched_ControllSettings = false
                if GeneralSetting[3] == AnimationSetting[5] then
                    matched_AnimationSetting = true
                    -- finding all subconstructs fitting the name
                    for _, SubConstructIdentifier in pairs(FindAllSubconstructs(I, GeneralSetting[1])) do
                        matched_SubconstructName = true
                        local Animation = LightAnimation_(I,SubConstructIdentifier,GeneralSetting[2])
                        if Animation.Valid then
                            Animation.PeriodTicks = AnimationSetting[1]
                            Animation.BurnTicks = AnimationSetting[2]
                            Animation.Intensity = AnimationSetting[3]
                            Animation.Range = AnimationSetting[4]
                            Animation:SetRange(I)
                            local RGB = AnimationSetting[6]
                            Animation:Color(I,RGB[1], RGB[2], RGB[3])
                            Animation.LinkId = GeneralSetting[4]
                            Animation.DistanceOfAnimations = GeneralSetting[5]
                            Animation.LoopOffset = GeneralSetting[6] or 0
                            -- loading controls from settings
                            for _, ControllSetting in pairs(ControllSettings) do
                                if GeneralSetting[3] == ControllSetting[1] then
                                    Animation.controll_channel = ControllSetting[2]
                                    break
                                end
                            end
                            MyLog(I,SYSTEM,"SYSTEM:   Animation_01 has "..tostring(#Animation.Lights).." lights")
                            table.insert(Animations,Animation)
                        end
                    end
                    break --once we found a AnimationSetting, we break out of the loop
                end
                if not matched_AnimationSetting then
                    MyLog(I,WARNING,"WARNING:   Animation named \""..tostring(GeneralSetting[3]).."\" has no AnimationSetting")
                end
                if not matched_SubconstructName then
                    MyLog(I,WARNING,"WARNING:   Animation named \""..tostring(GeneralSetting[3]).."\" has no correct named Subconstruct")
                end
            end
        end
        -- linking animations based on settings
        for Master_AnimationID, Master_Animation in pairs(Animations) do
            if Master_Animation.LinkId ~= nil then
                for Slave_AnimationID, Slave_Animation in pairs(Animations) do
                    if Slave_Animation.LinkId == Master_Animation.LinkId and Master_AnimationID ~= Slave_AnimationID then
                        Master_Animation:Link(I,Slave_Animation)
                        Animations[Slave_AnimationID] = nil
                    end
                end
            end
        end
        for AnimationId, Animation in pairs(Animations) do
            Animation.AnimationId = AnimationId
        end
        return Animations
    end

--||| UPDATE4
    -- updates / controlls all LightAnimations
    function UpdateLights(I)
        for Id, Animation in pairs(Animations) do
            Animation:ControllStart(I,Id) -- waits for controlls to copy animation into ActiveAnimations
        end
        -- keeps active animations running
        MyLog(I,SYSTEM,"SYSTEM:   "..#ActiveAnimations.." active animations")
        for Id, Animation in pairs(ActiveAnimations) do
            MyLog(I,SYSTEM,"SYSTEM:   animating animation: "..Id)
            Animation:Run(I,Id)
            Animation:ControllEnd(I,Id)
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

    -- is called by the game to update this code
    function Update(I)
        ClearMyLogs(I)
        LightAnimations(I)
    end
