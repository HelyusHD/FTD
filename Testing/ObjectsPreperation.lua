local function addTableValues(x, y)
return x.num + y.num
end

local metatable = {
    -- defines "+" 
    __add = addTableValues,
    __sub = function(x, y)
        return x.num - y.num
    end
}

local tbl1 = {num = 50}
local tbl2 = {num = 10}

-- assigns a metatable #2 to a table #1
setmetatable(tbl1, metatable)
setmetatable(tbl2, metatable) -- we only operate on tbl1, so we dont actually need a metatable for tbl2

-- works without metatable
--print(addTableValues(tbl1,tbl2))

-- does not work without metatables
print("tbl1 + tbl2 = "..tbl1 + tbl2) -- "+" is not defined for tables by default
print("tbl1 - tbl2 = "..tbl1 - tbl2)


--[[
    __index     = table[UnknownKey]   | when table[UnknownKey] == nil
    __add       = +
    __sub       = -
    __mul       = *
    __dif       = /
    __mod       = %
    __pow       = ^
    __concat    = ..
    __len       = #
    __eq        = ==
    __lt        = <
    __le        = <=
    __gt        = >
    __Ge        = >=
]]
