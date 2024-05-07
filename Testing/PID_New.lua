-- this is a LUA PID
-- at the bottom there is an example on how to use this

-- this is a PID object
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

--example how to use this:

-- lets create a new PID named "Pid01"
Pid_01 = PID()

-- lets set its gain integral and derivative (note that those settings work different than the ones in game)
Pid_01:settings(0.01, 0.1, 0.01)


-- this is how we get a drive from the PID
-- this should be executed every game tick
--drive = Pid01:drive(measurement, gametime, setpoint)
drive = Pid_01:drive(10, 0.25, 0)