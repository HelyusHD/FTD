local I = {}
function I:Log(message)
    print(message)
end

function I:ClearLogs()
    print("logs cleared")
end

function I:LogToHud(message)
    print("Hud: "..message)
end

return I