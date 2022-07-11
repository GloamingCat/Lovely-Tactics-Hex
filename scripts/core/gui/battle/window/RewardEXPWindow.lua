
--[[===============================================================================================

RewardEXPWindow
---------------------------------------------------------------------------------------------------
The window that shows the gained experience.

=================================================================================================]]

-- Imports
local PopupText = require('core/battle/PopupText')
local SimpleText = require('core/gui/widget/SimpleText')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

-- Alias
local yield = coroutine.yield

local RewardEXPWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides Window:createContent.
function RewardEXPWindow:createContent(...)
  Window.createContent(self, ...)
  self.done = false
  local font = Fonts.gui_medium
  local x = - self.width / 2 + self:paddingX()
  local y = - self.height / 2 + self:paddingY()
  local w = self.width - self:paddingX() * 2
  local title = SimpleText(Vocab.experience, Vector(x, y), w, 'center')
  self.content:add(title)
  y = y + 20
  for k, v in pairs(self.GUI.rewards.exp) do
    local battler = self.GUI.troop.battlers[k]
    -- Name
    local posName = Vector(x, y)
    local name = SimpleText(battler.name, posName, w / 2, 'left', font)
    self.content:add(name)
    -- EXP - Arrow
    local plusPos = Vector(x + w / 2, y - 2, 0)
    local plus = SimpleText('+', plusPos, w / 2, 'center')
    local exp = battler.job.exp
    local aw = plus.sprite:getWidth()
    local expw = w / 4 - aw / 2
    self.content:add(plus)
    -- EXP - Values
    local posEXP1 = Vector(x + w / 2, y)
    local posEXP2 = Vector(x + w / 2 + expw + plus.sprite:getWidth(), y)
    local exp1 = SimpleText(exp .. '', posEXP1, expw, 'left', font)
    local exp2 = SimpleText(v .. '', posEXP2, expw, 'left', font)    
    self.content:add(exp1)
    self.content:add(exp2)
    exp1.battler = battler
    exp1.value = exp
    exp2.value = v
    y = y + 12
  end
  self.soundPeriod = 5
  self.expSound = Config.sounds.exp
  self.expSpeed = 120
  self.levelupSound = Config.sounds.levelup
end

---------------------------------------------------------------------------------------------------
-- EXP Gain
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Show EXP gain.
function RewardEXPWindow:addEXP()
  local done, levelup
  local soundTime = self.soundPeriod
  repeat
    done, levelup = true, false
    for i = 4, #self.content, 4 do
      local exp1 = self.content[i]
      local exp2 = self.content[i + 1]
      if exp2.value > 0 then
        done = false
        local gain = math.min(math.floor(self.expSpeed * GameManager:frameTime()), exp2.value)
        local nextLevel = exp1.battler.job:levelsup(gain)
        exp1.battler.job:addExperience(gain)
        -- Level-up
        if nextLevel then
          local x = self:paddingX() - self.width / 2
          local y = exp1.position.y + 8
          local popupText = PopupText(x, y + 10, -10, GUIManager.renderer)
          popupText:addLine('Level ' .. nextLevel .. '!', 'popup_levelup', 'popup_levelup')
          popupText:popup()
          levelup = true
        end
        exp1.value = exp1.battler.job.exp
        exp1:setText('' .. exp1.value)
        exp1:redraw()
        exp2.value = exp2.value - gain
        exp2:setText('' .. exp2.value)
        exp2:redraw()
      end
    end
    soundTime = soundTime + GameManager:frameTime() * 60
    if self.expSound and soundTime >= self.soundPeriod then
      soundTime = soundTime - self.soundPeriod
      AudioManager:playSFX(self.expSound)
    end
    if levelup and self.levelupSound then
      AudioManager:playSFX(self.levelupSound)
    end
    yield()
  until done
end
-- Overrides Window:onConfirm.
function RewardEXPWindow:onConfirm()
  if self.done then
    self.result = 1
    self.fiber:interrupt()
    return
  end
  self.done = true
  self.fiber = GUIManager.fiberList:fork(self.addEXP, self)
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides Window:hide.
function RewardEXPWindow:hide(...)
  AudioManager:playSFX(Config.sounds.buttonConfirm)
  Window.hide(self, ...)
end
-- @ret(string) String representation (for debugging).
function RewardEXPWindow:__tostring()
  return 'EXP Reward Window'
end

return RewardEXPWindow
