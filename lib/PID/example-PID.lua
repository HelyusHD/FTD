function PID()
    return {
        -- those are the attributes of the PID
        Kg,
        Ki,
        Kd,
        setpoint,
        IMax =  1,
        IMin = -1,
        OutMax =  1,
        OutMin = -1,
        previousError = 0,
        integral = 0,
        derivative = 0,
        lastGameTime = 0,

        -- those are the methods of the PID
        settings = function(self,Kg,Ki,Kd)
            self.Kg = Kg
            self.Ki = Ki
            self.Kd = Kd
        end,
        drive = function(self,measurement,gametime,setpoint)
            self.setpoint = setpoint
            local error     = self.setpoint - measurement
            local timeDelta = 0.025
            local drive
        
            self.integral = self.integral + (error*timeDelta) * self.Ki
            if (self.integral > self.IMax) then self.integral = self.IMax end
            if (self.integral < self.IMin) then self.integral = self.IMin end
        
            self.derivative = (error - self.previousError)/(gametime-self.lastGameTime)
        
            drive = self.Kg*error + self.derivative*self.Kd + self.integral
            if (drive > self.OutMax) then drive = self.OutMax end
            if (drive < self.OutMin) then drive = self.OutMin end
        
            self.previousError = error
            self.lastGameTime = gametime
            return drive
        end
    }
end

-- how this would look in FTD
-- this will controll pitch, roll and altitude of a craft
function Update(I)
    if Pid_Roll == nil then
        Pid_Roll = PID()
        Pid_Roll:settings(0.001, 0.0001, 0.1)
    end
    if Pid_Pitch == nil then
        Pid_Pitch = PID()
        Pid_Pitch:settings(0.005, 0.0001, 0.1)
    end
    if Pid_Alt == nil then
        Pid_Alt = PID()
        Pid_Alt:settings(0.05, 0.001, 0.1)
    end
    local R = I:GetConstructRoll()
    if R > 180 then R = R -360 end
    local roll  = Pid_Roll:drive(-R, I:GetGameTime(),0)
    local pitch = Pid_Pitch:drive(-I:GetConstructPitch(), I:GetGameTime(), 0)
    local alt   = Pid_Alt:drive(I:GetConstructPosition().y, I:GetGameTime(), 100)
    I:SetPropulsionRequest(3, roll)
    I:SetPropulsionRequest(4, pitch)
    I:SetPropulsionRequest(7, alt)
    I:Log("roll: "..roll.."   pitch: "..pitch.."   alt: "..alt)
end