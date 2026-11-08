--[[
	MailRushServer (Script)
	Where it goes: ServerScriptService > MailRushServer

	This is the referee. It runs on the Roblox server, not on the player's computer,
	so players cannot cheat it. It decides when a day starts, counts letters,
	works out the stars, and hands out cash.

	It expects these things in the Workspace:
	  - A Folder called "Mailboxes" holding your mailboxes (Parts or Models).
	  - A Model called "PostOffice" that contains a Part called "ClockInDesk".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

------------------------------------------------------------
-- Remotes: how the server talks to each player's screen
------------------------------------------------------------

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local function getRemote(name)
	local remote = remotes:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotes
	end
	return remote
end

local DayStarted = getRemote("DayStarted")       -- server -> player: your day began
local LetterDelivered = getRemote("LetterDelivered") -- server -> player: one letter landed (or a hint)
local DayFinished = getRemote("DayFinished")     -- server -> player: here are your stars

------------------------------------------------------------
-- Find the world pieces
------------------------------------------------------------

local mailboxFolder = Workspace:WaitForChild("Mailboxes")
local postOffice = Workspace:WaitForChild("PostOffice")
local clockDesk = postOffice:WaitForChild("ClockInDesk")

-- A mailbox can be a single Part or a Model full of parts.
-- This returns the Part we attach the "Deliver" prompt to.
local function getPromptPart(mailbox)
	if mailbox:IsA("BasePart") then
		return mailbox
	end
	if mailbox:IsA("Model") then
		return mailbox.PrimaryPart or mailbox:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function getMailboxes()
	local list = {}
	for _, child in ipairs(mailboxFolder:GetChildren()) do
		if getPromptPart(child) then
			table.insert(list, child)
		end
	end
	return list
end

-- Puts a "hold E" prompt on a part, or reuses one that is already there.
local function addPrompt(part, actionText, objectText, holdSeconds)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Parent = part
	end
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = holdSeconds
	prompt.MaxActivationDistance = Config.DELIVER_DISTANCE
	prompt.RequiresLineOfSight = false
	return prompt
end

------------------------------------------------------------
-- Player stats shown on the leaderboard (top right in game)
------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = stats

	local stars = Instance.new("IntValue")
	stars.Name = "Stars"
	stars.Parent = stats
end)

------------------------------------------------------------
-- Each player's current day
------------------------------------------------------------

-- days[player] = { startTime = number, delivered = { [mailbox] = true }, count = number, total = number }
local days = {}

Players.PlayerRemoving:Connect(function(player)
	days[player] = nil
end)

local function starsFor(seconds)
	if seconds <= Config.PAR_SECONDS then
		return 3
	elseif seconds <= Config.PAR_SECONDS * Config.TWO_STAR_MULTIPLIER then
		return 2
	else
		return 1
	end
end

local function addCash(player, amount)
	local stats = player:FindFirstChild("leaderstats")
	if stats and stats:FindFirstChild("Cash") then
		stats.Cash.Value = stats.Cash.Value + amount
	end
end

local function addStars(player, amount)
	local stats = player:FindFirstChild("leaderstats")
	if stats and stats:FindFirstChild("Stars") then
		stats.Stars.Value = stats.Stars.Value + amount
	end
end

local function startDay(player)
	local total = #getMailboxes()
	days[player] = {
		startTime = os.clock(),
		delivered = {},
		count = 0,
		total = total,
	}
	DayStarted:FireClient(player, {
		total = total,
		parSeconds = Config.PAR_SECONDS,
	})
	print(player.Name .. " clocked in. Letters to deliver: " .. total)
end

local function finishDay(player)
	local day = days[player]
	if not day then
		return
	end

	local seconds = os.clock() - day.startTime
	local stars = starsFor(seconds)
	local bonus = Config.CASH_BONUS[stars] or 0

	addCash(player, bonus)
	addStars(player, stars)
	days[player] = nil

	DayFinished:FireClient(player, {
		seconds = seconds,
		stars = stars,
		parSeconds = Config.PAR_SECONDS,
		bonus = bonus,
	})
	print(string.format("%s clocked out in %.1f seconds for %d stars", player.Name, seconds, stars))
end

------------------------------------------------------------
-- The Post Office desk: clock in, and later clock out
------------------------------------------------------------

local deskPrompt = addPrompt(clockDesk, "Clock in / out", "Post Office", 0.5)

deskPrompt.Triggered:Connect(function(player)
	local day = days[player]
	if not day then
		startDay(player)
	elseif day.count >= day.total then
		finishDay(player)
	else
		-- Still letters in the bag. Nudge the player instead of ending the day.
		LetterDelivered:FireClient(player, {
			count = day.count,
			total = day.total,
			message = "You still have " .. (day.total - day.count) .. " letters in your bag!",
		})
	end
end)

------------------------------------------------------------
-- The mailboxes
------------------------------------------------------------

for _, mailbox in ipairs(getMailboxes()) do
	local part = getPromptPart(mailbox)
	local prompt = addPrompt(part, "Deliver letter", mailbox.Name, Config.DELIVER_HOLD_SECONDS)

	prompt.Triggered:Connect(function(player)
		local day = days[player]
		if not day then
			-- Not clocked in yet, so this mailbox does nothing.
			LetterDelivered:FireClient(player, {
				count = 0,
				total = 0,
				message = "Clock in at the Post Office first!",
			})
			return
		end
		if day.delivered[mailbox] then
			-- Already delivered here today. Ignore the second press.
			return
		end

		day.delivered[mailbox] = true
		day.count = day.count + 1
		addCash(player, Config.CASH_PER_LETTER)

		LetterDelivered:FireClient(player, {
			mailbox = mailbox,
			count = day.count,
			total = day.total,
			cash = Config.CASH_PER_LETTER,
		})
	end)
end

print("Mail Rush server ready. Mailboxes found: " .. #getMailboxes())
