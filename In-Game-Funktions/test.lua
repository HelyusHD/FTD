local function adjust_path()
    local info = debug.getinfo(1, "S")
    local script_path = info.source:match("^@?(.*[\\/])")
    if script_path then
        package.path = script_path .. "?.lua;" .. package.path
    else
        print("Error: Could not determine the script path.")
    end
end
adjust_path()

local Vector3 = require("FTD-lib.Vector3")
local Quaternion = require("FTD-lib.Quaternion")
local I = require("FTD-lib.main")
print(Vector3(1,2,3).y)
print(Quaternion(0,0,0,1).y)
I:Log("health: "..I:GetHealthFraction())
