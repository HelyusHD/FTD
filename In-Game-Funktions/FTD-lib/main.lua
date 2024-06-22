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


I = {}
I.__index = I

setmetatable(I, {
    __call = function (cls, ...)
        return cls.new(...)
    end,
})

function I.new()
    local self = setmetatable({}, I)
    return self
end

function I:merge(other)
    for k, v in pairs(other) do
        self[k] = v
    end
end

I:merge(require("Logging_Debugging"))
I:merge(require("FTD.In-Game-Funktions.FTD-lib.Self_awareness"))
I:merge(require("FTD-lib.Components"))
I:merge(require("FTD-lib.Target_Info"))
I:merge(require("FTD-lib.SubConstructs"))

return I
