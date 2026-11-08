--[[
	MailRushClient (LocalScript)
	Where it goes: StarterPlayer > StarterPlayerScripts > MailRushClient

	This runs on each player's own computer and draws everything they see:
	the timer at the top, the letters count, the hints, the "+10" pop over a mailbox,
	and the stars screen at the end of the day.

	It builds the whole GUI in code so you do not have to click through
	dozens of properties in Studio. Change colors and sizes here.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local DayStarted = remotes:WaitForChild("DayStarted")
local LetterDelivered = remotes:WaitForChild("LetterDelivered")
local DayFinished = remotes:WaitForChild("DayFinished")

------------------------------------------------------------
-- Colors and fonts. Change these to restyle the whole game.
------------------------------------------------------------

local COLORS = {
	panel = Color3.fromRGB(30, 41, 59),
	panelLight = Color3.fromRGB(51, 65, 85),
	text = Color3.fromRGB(255, 255, 255),
	textQuiet = Color3.fromRGB(203, 213, 225),
	starOn = Color3.fromRGB(250, 204, 21),
	starOff = Color3.fromRGB(100, 116, 139),
	cash = Color3.fromRGB(74, 222, 128),
	button = Color3.fromRGB(59, 130, 246),
}
local FONT = Enum.Font.GothamBold

------------------------------------------------------------
-- Little helpers so building the GUI stays short
------------------------------------------------------------

local function makeFrame(parent, size, position, color)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	return frame
end

local function makeLabel(parent, size, position, text, textSize, color)
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.Font = FONT
	label.TextColor3 = color or COLORS.text
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = seconds - minutes * 60
	return string.format("%d:%04.1f", minutes, secs)
end

------------------------------------------------------------
-- Build the screen
------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "MailRushGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- The HUD at the top: timer, letters, and a hint line.
local hud = makeFrame(gui, UDim2.new(0, 360, 0, 96), UDim2.new(0.5, 0, 0, 12), COLORS.panel)
hud.BackgroundTransparency = 0.15

local timerLabel = makeLabel(hud, UDim2.new(0.5, 0, 0, 40), UDim2.new(0, 0, 0, 6), "0:00.0", 32)
local lettersLabel = makeLabel(hud, UDim2.new(0.5, 0, 0, 40), UDim2.new(0.5, 0, 0, 6), "Letters: -", 22)
local hintLabel = makeLabel(hud, UDim2.new(1, -16, 0, 40), UDim2.new(0, 8, 0, 48), "Walk to the Post Office desk and hold E to clock in.", 16, COLORS.textQuiet)

-- The results card in the middle of the screen. Hidden until a day ends.
local results = makeFrame(gui, UDim2.new(0, 380, 0, 300), UDim2.new(0.5, 0, 0.5, -150), COLORS.panel)
results.Visible = false

makeLabel(results, UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 12), "Day complete!", 30)

local starLabels = {}
for i = 1, 3 do
	local star = makeLabel(results, UDim2.new(0, 70, 0, 70), UDim2.new(0.5, (i - 2) * 80 - 35, 0, 60), "★", 60, COLORS.starOff)
	starLabels[i] = star
end

local resultTime = makeLabel(results, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 140), "", 22)
local resultPar = makeLabel(results, UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 170), "", 16, COLORS.textQuiet)
local resultBonus = makeLabel(results, UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 196), "", 18, COLORS.cash)

local playAgain = Instance.new("TextButton")
playAgain.Size = UDim2.new(0, 200, 0, 44)
playAgain.Position = UDim2.new(0.5, -100, 1, -60)
playAgain.BackgroundColor3 = COLORS.button
playAgain.Text = "Back to work"
playAgain.TextSize = 20
playAgain.Font = FONT
playAgain.TextColor3 = COLORS.text
playAgain.Parent = results
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = playAgain

------------------------------------------------------------
-- Prompts: hide a mailbox's prompt for me once I have delivered there
------------------------------------------------------------

local function setPromptEnabled(mailbox, enabled)
	for _, descendant in ipairs(mailbox:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			descendant.Enabled = enabled
		end
	end
end

local function resetAllPrompts()
	local folder = workspace:FindFirstChild("Mailboxes")
	if folder then
		for _, mailbox in ipairs(folder:GetChildren()) do
			setPromptEnabled(mailbox, true)
		end
	end
end

-- A floating "+10" that rises out of the mailbox and fades away.
local function popCash(mailbox, amount)
	local part = mailbox:IsA("BasePart") and mailbox or mailbox:FindFirstChildWhichIsA("BasePart", true)
	if not part then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 120, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = makeLabel(billboard, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), "+" .. amount, 36, COLORS.cash)
	label.TextStrokeTransparency = 0.5

	local tween = TweenService:Create(billboard, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 7, 0),
	})
	local fade = TweenService:Create(label, TweenInfo.new(0.9), { TextTransparency = 1 })
	tween:Play()
	fade:Play()
	task.delay(1, function()
		billboard:Destroy()
	end)
end

------------------------------------------------------------
-- Day state
------------------------------------------------------------

local running = false
local startTime = 0
local parSeconds = 0

RunService.RenderStepped:Connect(function()
	if running then
		local elapsed = os.clock() - startTime
		timerLabel.Text = formatTime(elapsed)
		-- Turn the timer yellow once you pass par so you can feel the pressure.
		if elapsed > parSeconds then
			timerLabel.TextColor3 = COLORS.starOn
		else
			timerLabel.TextColor3 = COLORS.text
		end
	end
end)

DayStarted.OnClientEvent:Connect(function(info)
	running = true
	startTime = os.clock()
	parSeconds = info.parSeconds
	results.Visible = false
	resetAllPrompts()
	lettersLabel.Text = "Letters: 0 / " .. info.total
	hintLabel.Text = "Go! Hold E at each mailbox. Par is " .. formatTime(info.parSeconds) .. "."
end)

LetterDelivered.OnClientEvent:Connect(function(info)
	if info.message then
		hintLabel.Text = info.message
		return
	end

	lettersLabel.Text = "Letters: " .. info.count .. " / " .. info.total

	if info.mailbox then
		setPromptEnabled(info.mailbox, false)
		popCash(info.mailbox, info.cash or 0)
	end

	if info.count >= info.total then
		hintLabel.Text = "All delivered! Run back to the Post Office and clock out."
	else
		hintLabel.Text = (info.total - info.count) .. " to go!"
	end
end)

DayFinished.OnClientEvent:Connect(function(info)
	running = false
	timerLabel.Text = formatTime(info.seconds)
	timerLabel.TextColor3 = COLORS.text

	for i = 1, 3 do
		if i <= info.stars then
			starLabels[i].TextColor3 = COLORS.starOn
		else
			starLabels[i].TextColor3 = COLORS.starOff
		end
	end

	resultTime.Text = "Your time: " .. formatTime(info.seconds)
	resultPar.Text = "Par: " .. formatTime(info.parSeconds) .. "   2 stars under " .. formatTime(info.parSeconds * 1.5)
	if info.bonus > 0 then
		resultBonus.Text = "Bonus: +" .. info.bonus .. " cash"
	else
		resultBonus.Text = "No bonus. Beat par for extra cash!"
	end

	results.Visible = true
	hintLabel.Text = "Clock in again at the desk for a new day."
	resetAllPrompts()
end)

playAgain.MouseButton1Click:Connect(function()
	results.Visible = false
end)
