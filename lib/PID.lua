PidCount = 10

-- PID SETTINGS
--                      P,            D,         I,        OutMax,   OutMin,    IMax,    IMin
Pid_01_Settings      = {0.1,       0.08,     0.08,         1,       -1,       1,      -1}



-- reads PID settings
function InitPID(pidData,PidIndex)
    PIDs[PidIndex].Kp            = pidData[1]
    PIDs[PidIndex].Kd            = pidData[2]
    PIDs[PidIndex].Ki            = pidData[3]
    PIDs[PidIndex].OutMax        = pidData[4]
    PIDs[PidIndex].OutMin        = pidData[5]
    PIDs[PidIndex].IMax          = pidData[6]
    PIDs[PidIndex].IMin          = pidData[7]
    PIDs[PidIndex].integral      = 0
    PIDs[PidIndex].previousError = 0
end


-- updates PID settings
function SetPids(I)
    if not PIDs then
        PIDs = {}
        for i = 1, PidCount do
            PIDs[i] = {}
        end
    end

	if Pid_01_Settings_last ~= Pid_01_Settings then
		InitPID(Pid_01_Settings,1)
	end
    Pid_01_Settings_last = Pid_01_Settings
end


-- the actual PID
function GetPIDOutput(SetPoint, measurement, PidIndex)
    local error     = SetPoint - measurement
    local timeDelta = 0.025
    local derivative
    local output
    if PIDs[PidIndex] == nil then
        SetPids(I)
        if PIDs[PidIndex] == nil then
            return (0,nil)
        else
            local PID = PIDs[PidIndex]

            PID.integral = PID.integral + (error*timeDelta) * PID.Ki
            if (PID.integral > PID.IMax) then PID.integral = PID.IMax end
            if (PID.integral < PID.IMin) then PID.integral = PID.IMin end

            derivative = (error - PID.previousError)/timeDelta

            output = PID.Kp*error + PID.Kd*derivative + PID.integral
            if (output > PID.OutMax) then output = PID.OutMax end
            if (output < PID.OutMin) then output = PID.OutMin end

            PID.previousError = error
            return output,PID
        end
    end
end