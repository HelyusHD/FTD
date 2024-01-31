-- chapters --
-- 1. guidance groups
-- 2. missile behaviours
-- 3. prediction guidance

-- Each setting has already some examples so you can better understand how to set one up.

-- To give you an overiew on what you are looking at:
-- There are 3 big settings.

-- First there are missile controllers
-- A missile controller connects the launch pads, the ai, the bahaviour and the guidance.
-- This is everything a missile needs to be controlled.

-- Then there are missile behaviours.
-- A missile behaviour defines a method for a missiles to get to the enemy.

-- Last there are prediction guidances
-- A prediction guidance will predict the position of the enemie.
-- This will allow you to hit fast and rapidly moving targets.

-- missile controllers --
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- I have already created 2 different missile controllers.
-- You can give luanchers one of the names from "LaunchpadName" 
-- and they will be controlled by the Ai named like the "ControllingAiName" says
-- and they will behave like "MissileBehaviourName" says
-- and they will aim ahead like "PredictionName" says.
-- You can remove or add groups.
-- You can change the settings of a group, which are:
-- 1. LaunchpadName
-- 2. ControllingAiName
-- 3. MissileBehaviourName
-- 4. PredictionName: possible otions: "APN"

-- missile behaviours --
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-- Here you can define different behaviours for missiles.
-- You can then tell a missile group, what behaviour to use.
-- To do so, just match "FlightBehaviourName" and "MissileBehaviourName" and
-- the GuiadanceGroup will know what MissileBehaviour to use

-- There are multiple BehaviourType to choose from. They each require different settings.

-- 1.
-- BehaviourTypeName: "Diving"
-- This BehaviourType has 4 options:
-- 1. FlightBehaviourName: A GuiadanceGroup with this MissileBehaviourName will use this BehaviourType.
-- 2. CruisingAltitude: The cruising altitude the missile will stay at, bevore diving on the enemy
-- 3. DivingRadius: The distance to the enemy (no respect to altitude difference) below which we dive.
-- 4. PredictionTime: We behave depending on where we will be in this many seconds. Does not help hitting the target.
--                    This will help sticking to the CruisingAltitude and DivingRadius.
                      0 - 3 works for most missiles.

-- 2.
-- BehaviourTypeName: "Bombing"
-- This BehaviourType has 3 options:
-- 1. FlightBehaviourName: A GuiadanceGroup with this MissileBehaviourName will use this BehaviourType.
-- 2. AimPointUpShift: We aim above the actual aimpoint, to drop the bomb on top of the enemie.
-- 3. DivingRadius: Thats the distance below we stop aiming above the actual aimpoint and try to strike.

--3.
-- BehaviourTypeName: "CustomCurve"
-- not done yet

--4.
-- BehaviourTypeName: "Orbit"
-- This BehaviourType has 6 options:
-- 1. Radius: the radius if the orbit
-- 2. HightOffset: relative altitude to the target
-- 3. MaxHight: highest allowed altitude
-- 4. MinHight: lowest allowed altitude
-- 5. WhiggleRadius: additional rotation to irretate enemy counter measurements
-- 6. T: time for one rotation of the whiggle motion

--5.
-- BehaviourTypeName: "Straight"
-- This BehaviourType has 2 options:
-- 1. MaxHight: highest allowed altitude
-- 2. MinHight: lowest allowed altitude

-- prediction guidances --
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-- Here you can define different predictions for missiles.
-- You can then tell a missile group, what prediction to use.
-- To do so, just match "GuidanceName" and "GuidanceName" and
-- the GuiadanceGroup will know what MissileGuidance to use

-- There are multiple GuidanceType to choose from. They each require different settings.

-- 1.
-- GuidanceType: "Default"
-- Does nothing special at all
-- This GuidanceType has 0 option:

-- 2.
-- GuidanceType: "APN"
-- This GuidanceType has 3 options:
-- 1. LockingAngle: below this bearing angle, the APN kicks in
-- 2. UnlockingAngle: above this bearing angle, the APN disables
-- 3. PropConst: how aggressive the missile turns.
--    2.65 is a great value for most missiles.