PermanentInit = false


SETTINGS = {SystemName = "gimbal"}

DebugLevel = 50


-- returns lenght of list with not ordered indexes
function ListLenght(list)
    local i = 0
    for _, val in pairs(list) do
        i = i + 1
    end
    return i
end



function MyLog(I,priority,message)
    if priority <= DebugLevel then
        I:Log(message)
    end
end



-- saves all gimbal systems in a list
-- it saves the default orientation as well
-- it saves all thrusters placed on a gimbal system (WIP)
GimbalThrusterInit_DONE = false
function GimbalThrusterInit(I)
    MyLog(I, 20, "20:UPDATE:   in GimbalThrusterInit() atempting to init GimbalThruster")
    local ERROR = false
    local GimbalSystems = {}
    local AllSubconstructsCount = I:GetAllSubconstructsCount()
    MyLog(I,100,"100:RUNNING:   in GimbalThrusterInit() AllSubconstructsCount = "..AllSubconstructsCount)
    local roll = I:GetConstructRoll()
    local pitch = I:GetConstructPitch()
    local yaw = I:GetConstructYaw()
    --local CraftRotation = Quaternion.Euler(roll, pitch, yaw)
    local CraftRotation = Quaternion.LookRotation(I:GetConstructForwardVector(), I:GetConstructUpVector())
    local SubConstructIdentifier = -1
    for index = 0 , AllSubconstructsCount - 1 do
        MyLog(I,100,"100:RUNNING:   in GimbalThrusterInit() index = "..index)
        local SubConstructIdentifier = I:GetSubConstructIdentifier(index)
        local SubConstructInfo = I:GetSubConstructInfo(SubConstructIdentifier)
        if SubConstructInfo.Valid then
            local CustomName = SubConstructInfo.CustomName
            MyLog(I,100,"100:RUNNING:   looking at spinner named "..CustomName)

            -- loading a new system
            if CustomName == SETTINGS.SystemName then
                local SubconstructsChildrenCount = I:GetSubconstructsChildrenCount(SubConstructIdentifier)
                if SubconstructsChildrenCount == 1 then
                    local SubConChdId = I:GetSubConstructChildIdentifier(SubConstructIdentifier, 0)
                    local SubConChdInfo = I:GetSubConstructInfo(SubConChdId)
                    if SubConChdInfo.Valid then
                        local GlobalRot1 = SubConstructInfo.Rotation
                        local GlobalRot2 = GlobalRot1 * I:GetSubConstructIdleRotation(SubConChdId) --in coordinate space of spinner1
                        local Rot1 = Quaternion.Inverse(CraftRotation) * GlobalRot1
                        local Rot2 = Quaternion.Inverse(CraftRotation) * GlobalRot2
                        if Rot1 ~= nil and Rot2 ~= nil then
                            local type = 9 -- 9 = propulsion blocks aka thrusters
                            local Count = I:Component_GetCount(type)
                            local Thrusters = {} -- list of all thrusters on this gimbal system
                            local DefaultThrusterRotation = Quaternion(0,0,0,0) -- direction the trusters face
                            local CenterOfThrust = Vector3(0,0,0) -- if there are <1 thrusters, we threat them as onr thruster at this position
                            local TotalMaxForce = 0 -- total thrust of all thrusters on this system
                            for blockIndex = 0, Count - 1 do
                                local BlockInfo = I:Component_GetBlockInfo(type,blockIndex)
                                if BlockInfo.Valid then
                                    if SubConChdId == BlockInfo.SubConstructIdentifier then
                                        table.insert(Thrusters, blockIndex)
                                        --DefaultThrusterRotation = MultiplyQuaternions(Rot2, BlockInfo.LocalRotation)
                                        LocalThrusterRotation = BlockInfo.LocalRotation
                                        DefaultThrusterRotation = Rot2 * LocalThrusterRotation

                                        local LocalPosition = BlockInfo.LocalPosition -- position in coordinate space of spinner 2
                                        local MaxForce = I:Component_GetFloatLogic_1(type, blockIndex, 3)
                                        CenterOfThrust = CenterOfThrust + LocalPosition * MaxForce
                                        TotalMaxForce = TotalMaxForce + MaxForce
                                    end
                                end
                                --checks if all thrusters face the same direction
                                if DefaultThrusterRotation ~= Quaternion(0,0,0,0) then
                                    if DefaultThrusterRotation_Last ~= nil then
                                        if DefaultThrusterRotation_Last ~= DefaultThrusterRotation then
                                            MyLog(I,10,"0:ERROR:   GimbalThrusterInit() Thrusters on system point in different directions")
                                            ERROR = true
                                        end
                                    end
                                    local DefaultThrusterRotation_Last = DefaultThrusterRotation
                                end
                            end
                            if #Thrusters > 0 then
                                CenterOfThrust = CenterOfThrust / TotalMaxForce

                                local VecUp = Vector3(0,1,0) -- default axis of spinners
                                local VecFd = Vector3(0,0,1) -- default direction of thrusters
                                GimbalSystems[SubConstructIdentifier] ={                            -- key = gimbal spinner 1. order
                                    SecAxisId = SubConChdId,                                        -- Id gimbal spinner 2. order
                                    Orientations = {Rot1 = Rot1, Rot2 = Rot2},                      -- rotations of spinners
                                    Thrusters = Thrusters,                                          -- indexes of thrusters on this gimbal system
                                    DefaultThrusterRotation = DefaultThrusterRotation,              -- default direction the trusters face
                                    CenterOfThrust = CenterOfThrust,                                -- behaves like single thruster at this position in local space of spinner 2
                                    TotalMaxForce = TotalMaxForce,                                  -- max force of all thrusters combined
                                    Axis1 = Rot1*VecUp,                                             -- rotation axis of the 1. order spinner
                                    Axis2 = Rot2*VecUp,                                             -- rotation axis of the 2. order spinner which is placed on the 1. spinner
                                    DefaultThrustDirection = DefaultThrusterRotation*VecFd,         -- direction the truster faces by default
                                    LocalThrusterRotation = LocalThrusterRotation,                  -- rotation of thruster in spinner2 coordinate space
                                    CommandsLast = {                                                -- command and respond of last frame (is updated in AimThruster())
                                        DesiredDirection = Vector3(0,0,0), 
                                        TotalRotation =  Quaternion(0,0,0,1),
                                        CenOfThstRelToCom = Vector3(0,0,0),
                                        Torque = Vector3(0,0,0)
                                    }
                                }
                                local tmp = GimbalSystems[SubConstructIdentifier]
                                MyLog(I, 5, "5:INIT   ID:"..SubConstructIdentifier.." CenOfThr:"..tostring(tmp.CenterOfThrust).." MaxF:"..tmp.TotalMaxForce)
                                MyLog(I, 20, "20:UPDATE:   in GimbalThrusterInit() found new GimbalSystem")
                            else
                                MyLog(I, 10, "10:SYSTEM:   in GimbalThrusterInit() #Thrusters on a system not > 0")
                            end
                        else
                            ERROR = true
                            MyLog(I, 0, "0:ERROR:   in GimbalThrusterInit() Rot1 or Rot2 == nil")
                        end
                    else
                        MyLog(I, 10, "10:SYSTEM:   in GimbalThrusterInit() SubConChdInfo.Valid == false")
                    end
                else
                    MyLog(I, 10, "10:SYSTEM:   in GimbalThrusterInit() SubconstructsChildrenCount ~= 1; was == "..SubconstructsChildrenCount)
                end
            end
        else
            MyLog(I, 10, "10:SYSTEM:   in GimbalThrusterInit() SubConstructInfo.Valid == false")
        end
    end
    if ListLenght(GimbalSystems) == 0 then
        MyLog(I, 0, "0:ERROR:   in GimbalThrusterInit() #GimbalSystems = 0")
        ERROR = true
    end
    -- calculate max possible torque for all 3 axis so that we can scale the command this system recives
    local CraftMaxTorque = Vector3(0,0,0)
    for SubConstructIdentifier, Data in pairs(GimbalSystems) do
        local CommandsLast = Data.CommandsLast
        local CraftRotation = Quaternion.LookRotation(I:GetConstructForwardVector(), I:GetConstructUpVector())
        local Com = I:GetConstructCenterOfMass()
        local TotalMaxForce = Data.TotalMaxForce
        local SubConstructInfo = I:GetSubConstructInfo(Data.SecAxisId)

        local CenOfThstRelToCom = Quaternion.Inverse(CraftRotation) * (SubConstructInfo.Position - Com) + (CommandsLast.TotalRotation * Data.CenterOfThrust)
        local TorqueRight = Vector3.Cross(CenOfThstRelToCom, Vector3.Cross(CenOfThstRelToCom, Vector3(1,0,0)) * TotalMaxForce)
        local TorqueUp = Vector3.Cross(CenOfThstRelToCom, Vector3.Cross(CenOfThstRelToCom, Vector3(0,1,0)) * TotalMaxForce)
        local TorqueForward = Vector3.Cross(CenOfThstRelToCom, Vector3.Cross(CenOfThstRelToCom, Vector3(0,0,1)) * TotalMaxForce)
        CraftMaxTorque = CraftMaxTorque + TorqueRight + TorqueUp + TorqueForward
    end

    if ERROR then
        return {}
    else
        GimbalThrusterInit_DONE = true
        return GimbalSystems, CraftMaxTorque
    end
end



function UpdateAxis(I, CraftRotation, SubConstructIdentifier, SubConChdId, LocalThrusterRotation)
    local CraftRotation = Quaternion.LookRotation(I:GetConstructForwardVector(), I:GetConstructUpVector())
    local ParentId = I:GetParent(SubConstructIdentifier)
    local GlobalRot1 = Quaternion(0,0,0,1)
    if ParentId == 0 then
        GlobalRot1 = CraftRotation * I:GetSubConstructIdleRotation(SubConstructIdentifier)
    else
        GlobalRot1 = I:GetSubConstructInfo(ParentId).Rotation * I:GetSubConstructIdleRotation(SubConstructIdentifier)
    end
    local GlobalRot2 = GlobalRot1 * I:GetSubConstructIdleRotation(SubConChdId) --in coordinate space of spinner1
    local Rot1 = Quaternion.Inverse(CraftRotation) * GlobalRot1
    local Rot2 = Quaternion.Inverse(CraftRotation) * GlobalRot2
    local VecUp = Vector3(0,1,0)
    local VecFd = Vector3(0,0,1)
    local Axis1 = Rot1*VecUp
    local Axis2 = Rot2*VecUp
    local DefaultThrustDirection = Rot2 * LocalThrusterRotation * VecFd
    return Axis1, Axis2, DefaultThrustDirection
end



function GimbalThruster(I)
    MyLog(I, 100, "100:RUNNING:   GimbalThruster()")
    if GimbalThrusterInit_DONE and not PermanentInit then
        GimbalThrusterUpdate(I)
    else
        GimbalSystems, CraftMaxTorque = GimbalThrusterInit(I)
    end
end



function Torque(I,TorqueCommand)
    local threhold = 1
    MyLog(I, 100, "100:RUNNING:   Torque()")
    local Corrections = {}
    local TotalTorque = -TorqueCommand
    local CraftRotation = Quaternion.LookRotation(I:GetConstructForwardVector(), I:GetConstructUpVector())
    local Com = I:GetConstructCenterOfMass()

    -- calculates the total torque
    for SubConstructIdentifier, Data in pairs(GimbalSystems) do
        local SubConstructInfo = I:GetSubConstructInfo(Data.SecAxisId)
        local CommandsLast = Data.CommandsLast
        local DesiredDirectionLast = CommandsLast.DesiredDirection
        local LocalPositionRelativeToCom = Quaternion.Inverse(CraftRotation) * (SubConstructInfo.Position - Com)
        local CenOfThstRelToCom = LocalPositionRelativeToCom + (CommandsLast.TotalRotation * Data.CenterOfThrust)
        local Drive = DesiredDirectionLast.magnitude
        local MaxForce = Data.TotalMaxForce
        local Torque = Vector3.Cross(CenOfThstRelToCom, DesiredDirectionLast * Drive * MaxForce)
        TotalTorque = TotalTorque + Torque
        -- stores produced torque of all thusters
        GimbalSystems[SubConstructIdentifier].CommandsLast.CenOfThstRelToCom = CenOfThstRelToCom
        GimbalSystems[SubConstructIdentifier].CommandsLast.Torque = Torque
    end
    local MaxIterations = 2 -- how often should we try to fix the torque? 
    local i = 0


    while TotalTorque.magnitude > threhold and (i <= MaxIterations -1)  do
        MyLog(I,12,"12:UPDATE   total torque:"..tostring(TotalTorque).."  TotalTorque.magnitude:"..TotalTorque.magnitude)
        i = i+1

        local TorqueList = {}
        -- iterates all systems
        for SubConstructIdentifier, Data in pairs(GimbalSystems) do
            local CommandsLast = Data.CommandsLast
            local CenOfThstRelToCom = CommandsLast.CenOfThstRelToCom -- this changes a little bit, when thrusters are rotated, but I ignore this small error
            local TotalMaxForce = Data.TotalMaxForce
            local BestCorrection = Vector3.Cross(CenOfThstRelToCom, TotalTorque / (CenOfThstRelToCom.magnitude ^ 2) / TotalMaxForce)   -- what a thruster should do to reduce thrust as best as possible
            if BestCorrection.magnitude > 1 then BestCorrection = BestCorrection.normalized end -- a thruster can only go up to 100% thrust 
            table.insert(TorqueList, {
                BestCorrection = BestCorrection,                                                                                            -- max new contribution to the reduction of the total torque
                SubConstructIdentifier = SubConstructIdentifier,
                NewTorque = TotalTorque + (Vector3.Cross(CenOfThstRelToCom, BestCorrection * TotalMaxForce) - CommandsLast.Torque)  -- the effect this would have the craft | used to sort the list
            })
        end

        -- uses best suited thruster
        table.sort(TorqueList, function(a, b) return a.NewTorque.magnitude < b.NewTorque.magnitude end) -- TorqueList[1] is the first thruster to adress to fix torque
        local tmp = ""
        for _, TorqueInfo in pairs(TorqueList) do
            tmp = tmp..(" | ID:"..TorqueInfo.SubConstructIdentifier.."  Drive:"..TorqueInfo.BestCorrection.magnitude.."  NewTorque:"..tostring(TorqueInfo.NewTorque.magnitude))
        end
        MyLog(I,12,"12:UPDATE "..tmp)
        local TorqueInfo = TorqueList[1]
        local SubConstructIdentifier = TorqueInfo.SubConstructIdentifier
        local NewTorque = TorqueInfo.NewTorque
        local Data = GimbalSystems[SubConstructIdentifier]
        local CenOfThstRelToCom = Data.CommandsLast.CenOfThstRelToCom

        local BestCorrection = TorqueInfo.BestCorrection -- command vector for the system
        local Torque = Vector3.Cross(CenOfThstRelToCom, BestCorrection * Data.TotalMaxForce)
        TotalTorque = NewTorque

        MyLog(I,11,"11:UPDATE   iteration "..i.." System "..SubConstructIdentifier.." with command = "..tostring(BestCorrection).." TotalTorque = "..tostring(TotalTorque))
        Corrections[SubConstructIdentifier] = BestCorrection

        -- updates orientations
        GimbalSystems[SubConstructIdentifier].CommandsLast.Torque = Torque -- we change this in order to re sort the list
        GimbalSystems[SubConstructIdentifier].CommandsLast.DesiredDirection = 
    end

    
    return Corrections -- a list of vectors
end


--gets command and sends it to the trusters
function GimbalThrusterUpdate(I)
    MyLog(I,100,"100:RUNNING:   in GimbalThrusterUpdate() #GimbalSystems = "..ListLenght(GimbalSystems))

    -- getting command
    local ForwardRequest = I:GetPropulsionRequest(0) + I:GetPropulsionRequest(6)
    local UpRequest = I:GetPropulsionRequest(7)
    local RightRequest = I:GetPropulsionRequest(8)
    local CraftRotation = Quaternion.LookRotation(I:GetConstructForwardVector(), I:GetConstructUpVector())
    local DesiredDirection = Quaternion.Inverse(CraftRotation) * Vector3(RightRequest,UpRequest,ForwardRequest)
    local DesiredTorque = Vector3(I:GetPropulsionRequest(4) * CraftMaxTorque.x ,-I:GetPropulsionRequest(5) * CraftMaxTorque.y, I:GetPropulsionRequest(3) * CraftMaxTorque.z)

    local Corrections = Torque(I,DesiredTorque) -- vector represents torque command from ai
    MyLog(I,10,"10:UPDATE:   "..ListLenght(Corrections).." corrections calculated")

    for SubConstructIdentifier, Data in pairs(GimbalSystems) do
        local corrected = false
        for CorrectionSubConstructIdentifier in pairs(Corrections) do
            if SubConstructIdentifier == CorrectionSubConstructIdentifier then
                MyLog(I,10,"10:UPDATE:   corrected spinner "..SubConstructIdentifier.." in direction "..tostring(Corrections[SubConstructIdentifier]))
                AimThruster(I,SubConstructIdentifier,Corrections[SubConstructIdentifier])
                corrected = true
            end
        end
        if not corrected then
            MyLog(I,50,"50:UPDATE:   aimed spinner "..SubConstructIdentifier.." in direction "..tostring(DesiredDirection))
            AimThruster(I,SubConstructIdentifier,DesiredDirection)
        end
    end
end



-- aims a given gimbal system in any direction
-- controls thruster based on the magnitude of the direction vector
function AimThruster(I,SubConstructIdentifier,DesiredDirection)
    local Data = GimbalSystems[SubConstructIdentifier]

    MyLog(I,100,"100:RUNNING:   in GimbalThruster() SubConstructIdentifier = "..SubConstructIdentifier)
    local Axis1 = Data.Axis1                                                   -- rotation axis of the 1. order spinner
    local Axis2 = Data.Axis2                                                   -- rotation axis of the 2. order spinner which is placed on the 1. spinner
    local DefaultThrustDirection = Data.DefaultThrustDirection                       -- direction the truster faces by default
    MyLog(I,20,"20:UPDATE:   Axis1 = "..tostring(Axis1).."   Axis2 = "..tostring(Axis2).."   DefaultThrustDirection = "..tostring(DefaultThrustDirection))

    -- will update the axis in real time
    if false then
        local CraftRotation = Quaternion.LookRotation(I:GetConstructForwardVector(), I:GetConstructUpVector())
        Axis1, Axis2, DefaultThrustDirection = UpdateAxis(I, CraftRotation, SubConstructIdentifier, Data.SecAxisId, Data.LocalThrusterRotation)
    end

    local Projection = Vector3.ProjectOnPlane(DesiredDirection, Axis1) -- projection of DesiredDirection on plane defined by Axis1 in order to calculate Angl1
    local sign = -1
    if Vector3.Dot(DefaultThrustDirection, Vector3.Cross(Axis1,Axis2)) < 0 then sign = 1 end
    local AngleA1 = Vector3.SignedAngle(Vector3.Cross(Axis1,Axis2) * sign, Projection, Axis1)
    local Rot1 = Quaternion.AngleAxis(AngleA1, Axis1) -- rotation spinner 1 performes relative to craft
    local AngleA2 = Vector3.SignedAngle(Rot1 * DefaultThrustDirection, DesiredDirection, Rot1 * Axis2)

    -- aims spinners
    I:SetSpinBlockRotationAngle(SubConstructIdentifier, AngleA1)
    I:SetSpinBlockRotationAngle(Data.SecAxisId, AngleA2)

    -- controls thruster
    local Drive = DesiredDirection.magnitude
    for _, blockIndex in pairs(Data.Thrusters) do
        I:Component_SetFloatLogic_2(9, blockIndex, 0, Drive * 4, 1, 1)
    end

    Data.CommandsLast = {
        DesiredDirection = DesiredDirection,
        TotalRotation = Quaternion.FromToRotation(DefaultThrustDirection, DesiredDirection) -- total rotation performed by the spinners
    }
end



function Update(I)
    I:ClearLogs()
    GimbalThruster(I)
end
