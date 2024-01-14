

-- encodes characters into numbers in space ]0,1[
function Encoder(symbol)

    -- math eval.txt contains the decoder informations for a math eval component in the bb
    -- those are the encoder informations:
    local Symbols = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"," ","0","1","2","3","4","5","6","7","8","9","."}
    for i = 1, #Symbols do
        if symbol == Symbols[i] then return i/100 end
    end
    return 0
end


-- this is a class
-- it creates a object
-- the object sends characters to a breadboard
-- the breadboard sums all characters up and sends them to any component (like signs)
-- we do this because LUA can not interact with string arguments of any blocks, but the bb can!
TickThreshold = 2
function channel_(axisname, tick_clamp_max) 
    local channel = {
        axisname = axisname,  -- custom axisname used to send the signal
        string = "",        -- what we send
        ticks_since_last_action = 0,   -- last time we send a symbol, used to control the speed at which characters are being send
        position = 0            -- position of last symbol we send
    }

        function channel:SendString(string)
            self.string = string -- sets a new string
            self.position = 0
        end
        -- needs to be executed each tick to update the object and 
        function channel:Run(I)
            if self.ticks_since_last_action <= tick_clamp_max then
                self.ticks_since_last_action = self.ticks_since_last_action + 1
            end
            if self.position < #self.string and TickThreshold <= self.ticks_since_last_action then
                self.ticks_since_last_action = 0
                self.position = self.position + 1
                local EncodedSymbol = Encoder(string.sub(self.string, self.position, self.position))
                I:Log("axisname: "..self.axisname.."  EncodedSymbol: "..tostring(EncodedSymbol).."  symbol: "..string.sub(self.string, self.position, self.position))
                I:RequestCustomAxis(self.axisname,EncodedSymbol)
            end
        end
        function channel:Reset(I)
            self.ticks_since_last_action = -1
            self.timestamp = I:GetTime()
            I:RequestCustomAxis(self.axisname,-1)
        end
    return channel
end


function Update(I)
    ShowTime(I)
end


function time_(update_every_ticks)
    local Time = channel_("1",80)
    Time.update_every_ticks = update_every_ticks
    Time.ticks_since_last_timeprint = 0
    function Time:GameTime(I)
        self.ticks_since_last_timeprint = self.ticks_since_last_timeprint + 1
        if self.ticks_since_last_timeprint >= self.update_every_ticks then
            self.ticks_since_last_timeprint = 0
            Time:Reset(I)
            Time:SendString("game time: "..tostring(I:GetTime()))
        end
    end
    return Time
end


function ShowTime(I)
    if Time == nil then
        Time = time_(80)
    else
        Time:GameTime(I)
        Time:Run(I)
    end
end