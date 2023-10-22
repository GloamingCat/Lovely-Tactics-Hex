
-- ================================================================================================

--- A GUI text that is written character by character and interacts with text events and player
-- input. See `TextParser.Codes` for the codes to be used in the text.
---------------------------------------------------------------------------------------------------
-- @uimod Dialogue
-- @extend SimpleText

-- ================================================================================================

-- Imports
local SimpleText = require('core/gui/widget/SimpleText')

-- Class table.
local Dialogue = class(SimpleText)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `SimpleText:init`. 
-- @override
function Dialogue:init(...)
  SimpleText.init(self, ...)
  self.sprite.wrap = true
  self.soundFrequence = 4
  self.textSpeed = 40
  self.textSound = Config.sounds.text
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Whether the player pressed the button to pass the dialogue.
-- @treturn boolean
function Dialogue:buttonPressed()
  return InputManager.keys['confirm']:isTriggered() or InputManager.keys['cancel']:isTriggered() 
    or InputManager.keys['mouse1']:isTriggered() or InputManager.keys['mouse2']:isTriggered()
    or InputManager.keys['touch']:isTriggered()
end
--- Shows text interactively, character by character.
-- @tparam string text Raw text string.
function Dialogue:rollText(text)
  self.sprite:setText(text)
  local time = 0
  local skipPoint = self:findSkipPoint(time)
  local soundTime = self.soundFrequence
  while true do
  	-- Play character sound.
    if self.textSound and soundTime >= self.soundFrequence then
      soundTime = soundTime - self.soundFrequence
      AudioManager:playSFX(self.textSound)
    end
    -- Check if player skipped dialogue.
    skipPoint = self:findSkipPoint(time)
    if self:buttonPressed() then
      Fiber:wait()
      if skipPoint then
        time = skipPoint
      else
        break
      end
    end
    -- Update time.
    local previousTime = time
    time = time + GameManager:frameTime() * self.textSpeed
    if skipPoint then
      time = math.min(time, skipPoint + 1)
    end
    soundTime = soundTime + GameManager:frameTime() * self.textSpeed
    if time >= self.sprite.parsedLines.length then
    	self:triggerEvents(previousTime, time + 1)
    	break
    end
    -- Update cut point.
    if self.sprite.cutPoint ~= math.ceil(time) then
	    while not pcall(self.sprite.setCutPoint, self.sprite, math.ceil(time)) do
        time = time + 1
	    end
      self:triggerEvents(previousTime, time)
    end
    Fiber:wait()
  end
  self.sprite:setCutPoint(nil)
end
--- Triggers events in the given character (cut point) interval.
-- @tparam number min Interval's minimum (inclusive).
-- @tparam number max Interval's maximum (exclusive).
function Dialogue:triggerEvents(min, max)
	for _, event in ipairs(self.sprite.events) do
		if event.point >= min and event.point < max then
      if event.type == 'time' then
        -- Wait for x seconds.
        _G.Fiber:wait(event.content)
      elseif event.type == 'input' then
        -- Wait for player input.
        _G.Fiber:waitUntil(self.buttonPressed, self)
      elseif event.type == 'audio' then
        -- Play SFX.
        AudioManager:playSFX(event.content)
      end
    end
  end
end
--- Searchs for the next point in the text after player skips.
-- @tparam number min Current text character.
-- @treturn number Next skip point or nil if reached the end of text.
function Dialogue:findSkipPoint(min)
  for _, event in ipairs(self.sprite.events) do
    if event.point >= min and event.type == 'input' then
      return event.point
    end
  end
end

return Dialogue
