local I = {}

-- Returns the position of the construct
function I:GetConstructPosition()
    return Vector3(0,0,0)
end

-- Returns the forward pointing vector of the construct
function I:GetConstructForwardVector()
    return Vector3(0,0,1)
end

-- Returns the right pointing vector of the construct
function I:GetConstructRightVector()
    return Vector3(1,0,0)
end

-- Returns the up pointing vector of the construct
function I:GetConstructUpVector()
    return Vector3(0,1,0)
end

-- Returns the 'positive' size of the vehicle (right, up, forwards) relative to its origin
function I:GetConstructMaxDimensions()
    return Vector3(1,1,1)
end

-- Returns the 'negative' size of the vehicle (left, down, back) relative to its origin
function I:GetConstructMinDimensions()
    return Vector3(1,1,1)
end

-- Returns the roll angle in degrees
function I:GetConstructRoll()
    return 0
end

-- Returns the pitch angle in degrees
function I:GetConstructPitch()
    return 0
end

-- Returns the yaw angle in degrees
function I:GetConstructYaw()
    return 0
end

-- Returns the center of mass of the construct
function I:GetConstructCenterOfMass()
    return Vector3(0,0,0)
end

-- Returns the position of the AI mainframe at the specified index
function I:GetAiPosition(mainframeIndex)
    return Vector3(0,0,0)
end

-- Returns the magnitude of the velocity vector
function I:GetVelocityMagnitude()
    return 0
end

-- Returns the magnitude of the forwards velocity vector
function I:GetForwardsVelocityMagnitude()
    return 0
end

-- Returns the velocity vector
function I:GetVelocityVector()
    return Vector3(10,0,0)
end

-- Returns the normalized velocity vector
function I:GetVelocityVectorNormalized()
    return Vector3(1,0,0)
end

-- Returns the angular velocity vector
function I:GetAngularVelocity()
    return Vector3(0,0,0)
end

-- Returns the local angular velocity vector
function I:GetLocalAngularVelocity()
    return Vector3(0,0,0)
end

-- Returns the fraction of remaining ammo
function I:GetAmmoFraction()
    return 1
end

-- Returns the fraction of remaining fuel
function I:GetFuelFraction()
    return 1
end

-- Returns the fraction of remaining spares
function I:GetSparesFraction()
    return 1
end

-- Returns the fraction of remaining energy
function I:GetEnergyFraction()
    return 1
end

-- Returns the fraction of remaining power
function I:GetPowerFraction()
    return 1
end

-- Returns the fraction of remaining electric power
function I:GetElectricPowerFraction()
    return 1
end

-- Returns the fraction of remaining health
function I:GetHealthFraction()
    return 1
end

-- Returns the difference in health fraction over a given time period
function I:GetHealthFractionDifference(time)
    return 0
end

-- Returns whether the construct is docked
function I:IsDocked()
    return false
end

-- Returns the name of the blueprint
function I:GetBlueprintName()
    return "BlueprintName"
end

-- Returns the unique ID of the construct
function I:GetUniqueId()
    return 1234
end

return I
