-- Function to convert Euler angles to quaternion
-- Input: Three Euler angles (in radians) representing rotations around X, Y, and Z axes
-- Output: Corresponding quaternion
function eulerToQuaternion(rx, ry, rz)
    rx = math.rad(rx)
    ry = math.rad(ry)
    rz = math.rad(rz)
    local qx = math.sin(rx / 2) * math.cos(ry / 2) * math.cos(rz / 2) - math.cos(rx / 2) * math.sin(ry / 2) * math.sin(rz / 2)
    local qy = math.cos(rx / 2) * math.sin(ry / 2) * math.cos(rz / 2) + math.sin(rx / 2) * math.cos(ry / 2) * math.sin(rz / 2)
    local qz = math.cos(rx / 2) * math.cos(ry / 2) * math.sin(rz / 2) - math.sin(rx / 2) * math.sin(ry / 2) * math.cos(rz / 2)
    local qw = math.cos(rx / 2) * math.cos(ry / 2) * math.cos(rz / 2) + math.sin(rx / 2) * math.sin(ry / 2) * math.sin(rz / 2)
    
    return Quaternion(qx,qy,qz,qw)
end

-- calculates a vector for a mimic to position its decoration
-- you will have to use the BreadBoard from the example craft as well... and the mimic of course
function Pointer(I,pos)
    I:ClearLogs()
    local craft_rotation = eulerToQuaternion(-I:GetConstructRoll(),I:GetConstructYaw(),-I:GetConstructPitch())
    local rot_correction = Quaternion.Inverse(craft_rotation)
    local type = 25
    if pointer_positioning_block_id == nil then
        for index = 0, I:Component_GetCount(type)-1 do
            if I:Component_GetBlockInfo(type,index).Valid then
                if string.find(I:Component_GetBlockInfo(type,index).CustomName, "tag# Projector LUA project") then
                    pointer_positioning_block_id = index
                end
            end
        end
    end
    local global_mimic_position = I:Component_GetBlockInfo(type,pointer_positioning_block_id).Position + craft_rotation * Vector3(0,-1,0)
    I:Log("mimic_pos: "..tostring(global_mimic_position))
    I:Log("craft_pos: "..tostring(I:GetConstructPosition()))
    pos = rot_correction*(pos - global_mimic_position) / 100000
    I:RequestCustomAxis("Pointer_x",pos.x)
    I:RequestCustomAxis("Pointer_y",pos.y)
    I:RequestCustomAxis("Pointer_z",pos.z)
    I:Log(tostring(craft_rotation))
end

function Update(I)
    Pointer(I,I:GetConstructPosition() + Vector3(0,10,0))
end