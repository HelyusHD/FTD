local I = {}
local TargetInfo = {
    Valid = true,
    Priority = 0,
    Score = 1.0,
    AimPointPosition = Vector3(0,0,0),
    Team = 0,
    Protected = true,
    Position = Vector3(0,0,0),
    Velocity = Vector3(0,0,0),
    PlayerTargetChoice = false,
    Id = 1
}
local TargetPositionInfo = {
    Valid = true,
    Azimuth = 0.0,
    Elevation = 0.0,
    ElevationForAltitudeComponentOnly = 0.0,
    Range = 0.0,
    Direction = Vector3(1,0,0),
    GroundDistance = 0.0,
    AltitudeAboveSeaLevel = 0.0,
    Position = Vector3(0,0,0),
    Velocity = Vector3(0,0,0)
}

function I:GetNumberOfMainframes()
    return 0
end

function I:GetNumberOfTargets(mainframeIndex)
    return 0
end

function I:GetTargetInfo(mainframeIndex, targetIndex)
    return TargetInfo
end

function I:GetTargetPositionInfo(mainframeIndex, targetIndex)
    return TargetPositionInfo
end

return I