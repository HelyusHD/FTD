local function test(num)
    local function inside()
        a = num
    end
    inside()
end

test(11)
print(tostring(a))