PlayerControlledTurretCodeName = "BT"
AimingTurretCodeName = "AT"


ERROR  = 0  -- shows errors
UPDATE = 20 -- shows the effect of the code
SYSTEM = 30 -- shows the calculations
DebugLevel = UPDATE



function FindAllSubconstructs(I, CodeWord)
    local ChosenSubconstructs = {}
    local SubconstructsCount = I:GetAllSubconstructsCount()
    for index = 0, SubconstructsCount-1 do
        local SubConstructIdentifier = I:GetSubConstructIdentifier(index)
        if string.find(I:GetSubConstructInfo(SubConstructIdentifier).CustomName, CodeWord) then
            table.insert(ChosenSubconstructs, SubConstructIdentifier)
        end
    end
    return ChosenSubconstructs
end


function InitPCT(I)
    PCTinit = true
    PlayerControlledTurrets = {}
    ChosenSubconstructs = FindAllSubconstructs(I,PlayerControlledTurretCodeName)
    if #ChosenSubconstructs == 0 then
        MyLog(I,ERROR,"ERROR:   found no turrets to control")
        PCTinit = false
    end
    for key, SubConstructIdentifier in pairs(ChosenSubconstructs) do
        local PCT_ID = SubConstructIdentifier
        local IdleRotation = I:GetSubConstructIdleRotation(PCT_ID)

        local SubConstructInfo = I:GetSubConstructInfo(PCT_ID)
        local AimTurretId = -1
        for index = 0, I:GetSubconstructsChildrenCount(SubConstructIdentifier)-1 do
            local SubConstructChildIdentifier = I:GetSubConstructChildIdentifier(SubConstructIdentifier, index)
            if string.find(I:GetSubConstructInfo(SubConstructChildIdentifier).CustomName, AimingTurretCodeName) then
                AimTurretId = SubConstructChildIdentifier
            end
        end
        if AimTurretId == -1 then
            MyLog(I,ERROR,"ERROR:   found no aim commanding turret for turret: "..PCT_ID)
            PCTinit = false
        end
        local GlobalPosition = SubConstructInfo.Position
        local TurretIdentiefier
        local SubconstructsCount = I:GetAllSubconstructsCount()
        for index = -1, SubconstructsCount-1 do
            local SubConstructIdentifier_02 = I:GetSubConstructIdentifier(index)
            if index == -1 then SubConstructIdentifier_02 = 0 end
            for weaponIndex = 0 , I:GetWeaponCountOnSubConstruct(SubConstructIdentifier_02)-1 do
                if GlobalPosition == I:GetWeaponBlockInfoOnSubConstruct(SubConstructIdentifier_02, weaponIndex).Position then
                    TurretIdentiefier = {SubConstructIdentifier = SubConstructIdentifier, weaponIndex = weaponIndex}
                end
            end
        end


        PlayerControlledTurrets[key] =  {PCT_ID = PCT_ID,
                                        IdleRotation = IdleRotation,
                                        Parent = I:GetParent(PCT_ID),
                                        IsTurret = I:IsTurret(SubConstructIdentifier),
                                        TurretIdentiefier = TurretIdentiefier,
                                        AimTurretId = AimTurretId
                                        }       
    end
end



function AimPCT(I,key,PlayerControlledTurret)
    local PCT_ID = PlayerControlledTurret.PCT_ID
    local SubConstructInfo = I:GetSubConstructInfo(PCT_ID)
    local Position = SubConstructInfo.Position -- GlobalSpace
    local IdleRotation = PlayerControlledTurret.IdleRotation -- SubSpace
    local Parent = PlayerControlledTurret.Parent
    local ParentRotation -- GlobalSpace
    if Parent == 0 then
        ParentRotation = Quaternion.Euler(I:GetConstructPitch(), I:GetConstructYaw(), I:GetConstructRoll())
    else
        ParentRotation = I:GetSubConstructInfo(Parent).Rotation
    end
    local AxisGlobal = ParentRotation * IdleRotation * Vector3.up -- GlobalSpace


    local TargetDirection = I:GetSubConstructInfo(PlayerControlledTurret.AimTurretId).Forwards -- GlobalSpace
    local ProjectedDirection = Vector3.ProjectOnPlane(TargetDirection, AxisGlobal) -- GlobalSpace
    local AngleShould = Vector3.SignedAngle(ParentRotation * (IdleRotation * Vector3.forward), ProjectedDirection, AxisGlobal) -- GlobalSpace
    MyLog(I,SYSTEM,"SYSTEM:   projection: "..tostring(ProjectedDirection).." mag.: "..ProjectedDirection.magnitude.." global rot. axis: "..tostring(AxisGlobal))


    



    if PlayerControlledTurret.IsTurret then
        local TI = PlayerControlledTurret.TurretIdentiefier
        I:Log(tostring("SubConstructIdentifier; "..TI.SubConstructIdentifier).."   weaponIndex: "..tostring(TI.weaponIndex).."   Name: "..I:GetSubConstructInfo(TI.SubConstructIdentifier).CustomName)
        --I:AimWeaponInDirectionOnSubConstruct(TI.SubConstructIdentifier,TI.weaponIndex,TargetDirection.x,TargetDirection.y,TargetDirection.z,0)
        I:AimWeaponInDirection(TI.weaponIndex,TargetDirection.x,TargetDirection.y,TargetDirection.z,0)
    else
        I:SetSpinBlockRotationAngle(PCT_ID, AngleShould)
    end
end


function PlayerControlledTurretsUpdate(I)
    MyLog(I,UPDATE,"UPDATE:   PlayerControlledTurrets is controlling "..#PlayerControlledTurrets.." turrets")
    for key, PlayerControlledTurret in pairs(PlayerControlledTurrets) do
        AimPCT(I,key,PlayerControlledTurret)
    end
end


function Update(I)
    I:ClearLogs()
    if PCTinit == true then
        PlayerControlledTurretsUpdate(I)
    else
        InitPCT(I)
    end
end


function MyLog(I,priority,message)
    if priority <= DebugLevel then
        I:Log(message)
    end
end 