-- Quaternion.lua

Quaternion = {}
Quaternion.__index = Quaternion

setmetatable(Quaternion, {
    __call = function (cls, ...)
        return cls.new(...)
    end,
})

function Quaternion.new(w, x, y, z)
    local self = setmetatable({}, Quaternion)
    self.w = w or 0
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
    return self
end

function Quaternion.__add(a, b)
    return Quaternion(a.w + b.w, a.x + b.x, a.y + b.y, a.z + b.z)
end

function Quaternion.__sub(a, b)
    return Quaternion(a.w - b.w, a.x - b.x, a.y - b.y, a.z - b.z)
end

function Quaternion.__mul(a, b)
    if type(b) == "number" then
        return Quaternion(a.w * b, a.x * b, a.y * b, a.z * b)
    elseif type(a) == "number" then
        return Quaternion(a * b.w, a * b.x, a * b.y, a * b.z)
    else
        return Quaternion(
            a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
            a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
            a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
            a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w
        )
    end
end

function Quaternion.__div(a, b)
    if type(b) == "number" then
        return Quaternion(a.w / b, a.x / b, a.y / b, a.z / b)
    else
        error("Cannot divide two Quaternion objects")
    end
end

function Quaternion:magnitude()
    return math.sqrt(self.w * self.w + self.x * self.x + self.y * self.y + self.z * self.z)
end

function Quaternion:normalize()
    local mag = self:magnitude()
    if mag > 0 then
        return self / mag
    else
        return Quaternion(1, 0, 0, 0)
    end
end

function Quaternion:conjugate()
    return Quaternion(self.w, -self.x, -self.y, -self.z)
end

function Quaternion:inverse()
    local mag = self:magnitude()
    if mag > 0 then
        return self:conjugate() / (mag * mag)
    else
        error("Cannot invert a quaternion with zero magnitude")
    end
end

return Quaternion
