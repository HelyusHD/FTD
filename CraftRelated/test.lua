-- Function to approximate inverse of hight(alpha)
-- Parameters: h - the desired y(x) value, a - parameter a, b - parameter b
function approximateInverseFunction(h, a, b)
    local function hight(alpha)
        return math.cos(alpha) * a + math.cos(alpha * math.abs(math.cos(alpha / 2))) * b
    end

    -- Bisection method to approximate the inverse
    local epsilon = 1e-1 -- Desired accuracy
    local maxIterations = 20
    local left = -math.pi
    local right = 0
    local mid = (left + right) / 2

    for _ = 1, maxIterations do
        local value = hight(mid)
        local diff = value - h

        if math.abs(diff) < epsilon then
            return mid
        elseif diff < 0 then
            left = mid
        else
            right = mid
        end

        mid = (left + right) / 2
    end

    return nil -- No solution found within the specified iterations
end

-- Example usage
local a = 100
local b = -100
local f = -200
local alpha = approximateInverseFunction(f, a, b)

if alpha then
    print("Approximate alpha:", alpha/math.pi * 180)
    local control = math.cos(alpha) * a + math.cos(alpha * math.abs(math.cos(alpha / 2))) * b
    print("control = "..control)
else
    print("Solution not found within iterations")
end