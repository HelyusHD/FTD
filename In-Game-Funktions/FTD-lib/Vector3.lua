-- Vector3.lua

Vector3 = {}
Vector3.__index = Vector3

setmetatable(Vector3, {
    __call = function (cls, ...)
        return cls.new(...)
    end,
})

function Vector3.new(x, y, z)
    local self = setmetatable({}, Vector3)
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
    return self
end

function Vector3.__add(a, b)
    return Vector3(a.x + b.x, a.y + b.y, a.z + b.z)
end

function Vector3.__sub(a, b)
    return Vector3(a.x - b.x, a.y - b.y, a.z - b.z)
end

function Vector3.__mul(a, b)
    if type(a) == "number" then
        return Vector3(a * b.x, a * b.y, a * b.z)
    elseif type(b) == "number" then
        return Vector3(a.x * b, a.y * b, a.z * b)
    else
        return Vector3(a.x * b.x, a.y * b.y, a.z * b.z)
    end
end

function Vector3.__div(a, b)
    if type(b) == "number" then
        return Vector3(a.x / b, a.y / b, a.z / b)
    else
        error("Cannot divide two Vector3 objects")
    end
end

function Vector3:magnitude()
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function Vector3:normalize()
    local mag = self:magnitude()
    if mag > 0 then
        return self / mag
    else
        return Vector3(0, 0, 0)
    end
end

return Vector3