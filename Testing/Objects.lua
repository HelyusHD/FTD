-- can be considered an object
local t = {
    name = "Jack",
    age = 18,
    friends = {"Fred"},
}

-- some sort of class
local function Pet(name)
    return {
        -- just some data
        name = name or "Luis",
        status = "Hungry",

        -- a function aka "method" working on the object
        feed = function(self)
            if self.status == "Full" then
                print(self.name.." is already Full")
            else
                self.status = "Full"
                print(self.name.." was fed and is now "..self.status)
            end
        end
    }
end

local cat = Pet("Kitty")
local dog = Pet()

print(cat.status)
cat:feed() -- is the same as cat.feed(cat)
print(cat.status)
cat.feed(cat)

local function Dog(name, breed)
    local Dog = Pet(name)
    Dog.breed = breed
end


local l = Dog("Justin", "Poodle")