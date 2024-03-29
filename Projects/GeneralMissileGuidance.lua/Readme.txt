   chapters
   0. general information
   1. installing breadboard
   2. guidance groups
   3. missile behaviours
   4. prediction guidance
   5. check for new settings

   general information
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

   ALWAYS BE AWARE OF THE LOG INSIDE THE LUA BOX!
   It gives you important feedback and tells you if you did set up everything correct.

   You can download an example craft named "Example.blueprint".

   Copy the GeneralMissileGuiadance.lua file into a lua box and apply the changes.
   When you change anything inside the lua box, make sure to apply the changes.

   This code allowes you to design your own fun missile behaviours.
   This code will only guide and not fire missiles.
   Make sure each missile launch pad has a lua transreciver block connected to it.
   Make sure each missile has a lua reciver component.
   Make sure, your ai has enough processing power.
   Make sure, your craft has detection on the enemy.

   Each setting has already some examples so you can better understand how to set one up.
   To give you an overiew on what you are looking at:
   There are 3 big tables with settings in them.

   First there are missile controllers
   A missile controller connects the launch pads, the ai, the bahaviour and the guidance.
   This is everything a missile needs to be controlled.

   Then there are missile behaviours.
   A missile behaviour defines a method for a missiles to get to the enemy.

   Last there are prediction guidances.
   A prediction guidance will predict the position of the enemie.
   This will allow you to hit fast and rapidly moving targets.

   installing breadboard
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
   I strongly advice you to send the stability of the craft divided by 100 over the Misc Axis named "E".
   Once you installed such a breadboard, you can set "BreadboardInstalled" (at the top of the code) to true.
   Its set to false by default!
   There is an image on my GitHub named BreadBoard.png showing such a setup.

   missile controllers
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
   I have already created 2 different missile controllers.
   You can give luanchers one of the names from "LaunchpadName" 
   and they will be controlled by the Ai named like the "ControllingAiName" says
   and they will behave like "MissileBehaviourName" says
   and they will aim ahead like "PredictionName" says.
   You can remove or add groups.
   You can change the settings of a group, which are:
   1. LaunchpadName
   2. ControllingAiName
   3. MissileBehaviourName
   4. PredictionName: possible otions: "APN", "PG"
   5. Size: The size of the missiles ("small", "medium", "large", "huge")

   missile behaviours
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

   Here you can define different behaviours for missiles.
   You can then tell a missile group, what behaviour to use.
   To do so, just match "FlightBehaviourName" and "MissileBehaviourName" and
   the GuiadanceGroup will know what MissileBehaviour to use

   There are multiple BehaviourType to choose from. They each require different settings.

   1.
   BehaviourTypeName: "Diving"
   This BehaviourType has 4 options:
   1. FlightBehaviourName: A GuiadanceGroup with this MissileBehaviourName will use this BehaviourType.
   2. CruisingAltitude: The cruising altitude the missile will stay at, bevore diving on the enemy
   3. DivingRadius: The distance to the enemy (no respect to altitude difference) below which we dive.
   4. PredictionTime: We behave depending on where we will be in this many seconds. Does not help hitting the target.
                      This will help sticking to the CruisingAltitude and DivingRadius.
                      0 - 3 works for most missiles.

   2.
   BehaviourTypeName: "Bombing"
   This BehaviourType has 3 options:
   1. FlightBehaviourName: A GuiadanceGroup with this MissileBehaviourName will use this BehaviourType.
   2. AimPointUpShift: We aim above the actual aimpoint, to drop the bomb on top of the enemie.
   3. DivingRadius: Thats the distance below we stop aiming above the actual aimpoint and try to strike.

--3.
   BehaviourTypeName: "CustomCurve"
   not done yet

--4.
   BehaviourTypeName: "Orbit"
   This BehaviourType has 6 options:
   1. Radius: the radius if the orbit
   2. HightOffset: relative altitude to the target
   3. MaxHight: highest allowed altitude
   4. MinHight: lowest allowed altitude
   5. WhiggleRadius: additional rotation to irretate enemy counter measurements
   6. T: time for one rotation of the whiggle motion

--5.
   BehaviourTypeName: "Straight"
   This BehaviourType has 2 options:
   1. MaxHight: highest allowed altitude
   2. MinHight: lowest allowed altitude

   prediction guidances
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

   Here you can define different predictions for missiles.
   You can then tell a missile group, what prediction to use.
   To do so, just match "GuidanceName" and "GuidanceName" and
   the GuiadanceGroup will know what MissileGuidance to use

   There are multiple GuidanceType to choose from. They each require different settings.

   1.
   GuidanceType: "Default"
   Does nothing special at all
   This GuidanceType has 0 option:

   2.
   GuidanceType: "APN"
   This is the APN guidance you should already know from vanilla missiles.
   This GuidanceType has 3 options:
   1. LockingAngle: below this bearing angle, the APN kicks in
   2. UnlockingAngle: above this bearing angle, the APN disables
   3. PropConst: how aggressive the missile turns.
      2.65 is a great value for most missiles.

   3.
   GuidanceType: "PG"
   This is the prediction guidance you should already know from vanilla missiles.
   This GuidanceType has no options
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

   Last but not least you can decide on how fast you want the code to check for new Settings
   There is one option:
   1. UpdateSettingsInterval: How many seconds need to pass 