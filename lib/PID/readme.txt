This is a LUA PID.

oop-PID.lua is the code
example-PID.lua is an example for how to use the code
oop LUA PID.blueprint is an example craft

steps to use a PID:

creat new PID using
    <PID_NAME> = PID()

change settings of a PID
    <PID_NAME>:settings(gain, integral, derivitive)
    !!! integral and derivitive settings are on a different scale than the in game PID !!!

use a PID
    <PID_NAME>:drive(measurement,gametime,setpoint)

If you have questions, ping me on the official FTD Discord server.
Server: https://discord.gg/fromthedepths
Channel: https://discord.com/channels/203755725090979841/673486332911157248
Username: HelyusHD