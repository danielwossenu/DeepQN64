-- OPTIONS

RESET_FOR_TIME = false -- Set to true if you're trying to break the record, not just finish a run
BEAST_MODE = false -- WARNING: Do not engage. Will yolo everything, and reset at every opportunity in the quest for 1:47.

INITIAL_SPEED = 1500
AFTER_BROCK_SPEED = 1500
AFTER_MOON_SPEED = 500
E4_SPEED = 200

RESET_LOG = "./wiki/red/resets.txt"
VICTORY_LOG = "./wiki/red/victories.txt"

local CUSTOM_SEED  = nil -- Set to a known seed to replay it, or leave nil for random runs
local NIDORAN_NAME = "A" -- Set this to the single character to name Nidoran (note, to replay a seed, it MUST match!)
local PAINT_ON     = true -- Display contextual information while the bot runs

-- START CODE (hard hats on)

VERSION = "2.4.8"
CURRENT_SPEED = nil

local Data = require "data.data"

Data.init()

local Battle = require "action.battle"
local Textbox = require "action.textbox"
local Walk = require "action.walk"

local Combat = require "ai.combat"
local Control = require "ai.control"
local Strategies = require("ai."..Data.gameName..".strategies")

local Pokemon = require "storage.pokemon"

local Bridge = require "util.bridge"
local Input = require "util.input"
local Memory = require "util.memory"
local Paint = require "util.paint"
local Utils = require "util.utils"
local Settings = require "util.settings"

local hasAlreadyStartedPlaying = false
local oldSeconds
local running = true
local previousMap

-- HELPERS

function resetAll()
	Strategies.softReset()
	Combat.reset()
	Control.reset()
	Walk.reset()
	Paint.reset()
	Bridge.reset()
	Utils.reset()
	oldSeconds = 0
	running = false
	
	CURRENT_SPEED = INITIAL_SPEED
  	client.speedmode(INITIAL_SPEED)

	if CUSTOM_SEED then
		Data.run.seed = CUSTOM_SEED
		Strategies.replay = true
		p("RUNNING WITH A FIXED SEED ("..NIDORAN_NAME.." "..Data.run.seed.."), every run will play out identically!", true)
	else
		Data.run.seed = os.time()
		print("PokeBot v"..VERSION..": "..(BEAST_MODE and "BEAST MODE seed" or "Seed:").." "..Data.run.seed)
	end
	math.randomseed(Data.run.seed)
end


-- EXECUTE

p("Welcome to PokeBot "..Utils.capitalize(Data.gameName).." v"..VERSION, true)

Control.init()
Utils.init()
STREAMING_MODE = true

if CUSTOM_SEED then
	Strategies.reboot()
else
	hasAlreadyStartedPlaying = Utils.ingame()
end

Strategies.init(hasAlreadyStartedPlaying)

if hasAlreadyStartedPlaying and RESET_FOR_TIME then
	RESET_FOR_TIME = false
	p("Disabling time-limit resets as the game is already running. Please reset the emulator and restart the script if you'd like to go for a fast time.", true)
end

if STREAMING_MODE then
	if not CUSTOM_SEED or BEAST_MODE then
		RESET_FOR_TIME = true
	end
	Bridge.init(Data.gameName)
else
	if PAINT_ON then
		Input.setDebug(true)
	end
end



-- LOOP

local function generateNextInput(currentMap)
	if not Utils.ingame() then
		Bridge.pausegametime()
		if currentMap == 0 then
			if running then
				if not hasAlreadyStartedPlaying then
					if emu.framecount() ~= 1 then Strategies.reboot() end
					hasAlreadyStartedPlaying = true
				else
					resetAll()
				end
			else
				Settings.startNewAdventure()
			end
		else
			if not running then
				Bridge.liveSplit()
				running = true
			end
			Settings.choosePlayerNames()
		end
	else
		Bridge.time()
		Utils.splitCheck()
		local battleState = Memory.value("game", "battle")
		Control.encounter(battleState)

		local curr_hp = Combat.hp()
		Combat.updateHP(curr_hp)

		if curr_hp == 0 and not Control.canDie() and Pokemon.index(0) > 0 then
			Strategies.death(currentMap)
		elseif Walk.strategy then
			if Strategies.execute(Walk.strategy) then
				if Walk.traverse(currentMap) == false then
					return generateNextInput(currentMap)
				end
			end
		elseif battleState > 0 then
			if not Control.shouldCatch() then
				Battle.automate()
			end
		elseif Textbox.handle() then
			if Walk.traverse(currentMap) == false then
				return generateNextInput(currentMap)
			end
		end
	end
end

while true do
	local currentMap = Memory.value("game", "map")
	if currentMap ~= previousMap then
		Input.clear()
		previousMap = currentMap
	end
	if Strategies.frames then
		if Memory.value("game", "battle") == 0 then
			Strategies.frames = Strategies.frames + 1
		end
		Utils.drawText(0, 80, Strategies.frames)
	end
	if Bridge.polling then
		Settings.pollForResponse(NIDORAN_NAME)
	end

	if not Input.update() then
		generateNextInput(currentMap)
	end

	if STREAMING_MODE then
		local newSeconds = Memory.value("time", "seconds")
		if newSeconds ~= oldSeconds and (newSeconds > 0 or Memory.value("time", "frames") > 0) then
			Bridge.time(Utils.elapsedTime())
			oldSeconds = newSeconds
		end
	elseif PAINT_ON then
		Paint.draw(currentMap)
	end

	Input.advance()
	emu.frameadvance()
end

Bridge.close()
