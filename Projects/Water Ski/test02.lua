function Quaternion_(qx,qy,qz,qw)
    return {
        x = qx, y = qy, z = qz, w = qw,
        log = function(self,I)
            I:Log("Quaternion:("..self.x..", "..self.y..", "..self.z..", "..self.w..")")
        end
    }
end

function Update(I)
    I:ClearLogs()
    local degreesX = 0
    local degreesY = 10
    local degreesZ = 0 -- here, if this is 0, both ways return the same angles
    local quat = EulerToQuaternion(degreesX, degreesY, degreesZ)
    quat:log(I)
    --I:Log(tostring(quat))
    local Unity = (quat).eulerAngles
    local Diy   = quaternionToEuler(quat)
    I:Log("Unity: "..tostring(Unity).."\n    Diy: "..tostring(Diy))
    end
    
        function EulerToQuaternion(degreesX, degreesY, degreesZ)
            -- Convert degrees to radians
            local rx = math.rad(degreesZ)
            local ry = math.rad(degreesX)
            local rz = math.rad(degreesY)
    
            local qx = math.cos(rx / 2) * math.sin(ry / 2) * math.cos(rz / 2) + math.sin(rx / 2) * math.cos(ry / 2) * math.sin(rz / 2)
            local qy = math.cos(rx / 2) * math.cos(ry / 2) * math.sin(rz / 2) - math.sin(rx / 2) * math.sin(ry / 2) * math.cos(rz / 2)
            local qz = math.sin(rx / 2) * math.cos(ry / 2) * math.cos(rz / 2) - math.cos(rx / 2) * math.sin(ry / 2) * math.sin(rz / 2)
            local qw = math.cos(rx / 2) * math.cos(ry / 2) * math.cos(rz / 2) + math.sin(rx / 2) * math.sin(ry / 2) * math.sin(rz / 2)
            
            return Quaternion_(qx,qy,qz,qw)
            --return Quaternion(qx,qy,qz,qw)
        end
    
        function quaternionToEuler(quaternion)
            -- Extract the quaternion components
            local w = quaternion.w
            local x = quaternion.y
            local y = quaternion.x
            local z = quaternion.z
            
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
    