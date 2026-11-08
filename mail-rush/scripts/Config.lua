--[[
	Config (ModuleScript)
	Where it goes: ReplicatedStorage > Config

	These are the numbers that tune the game. Change one, press Play, see what happens.
	Everything else in the game reads from here, so this is the only place you edit numbers.
]]

local Config = {}

-- Finish the whole day in this many seconds for 3 stars.
Config.PAR_SECONDS = 90

-- Finish under PAR_SECONDS times this for 2 stars. 1.5 means 135 seconds when par is 90.
Config.TWO_STAR_MULTIPLIER = 1.5

-- Cash earned for every letter delivered.
Config.CASH_PER_LETTER = 10

-- Extra cash at clock-out, by star count.
Config.CASH_BONUS = {
	[3] = 50,
	[2] = 20,
	[1] = 0,
}

-- How far away (in studs) you can be from a mailbox and still deliver.
Config.DELIVER_DISTANCE = 10

-- How long you hold E at a mailbox before the letter goes in, in seconds.
Config.DELIVER_HOLD_SECONDS = 0.3

return Config
