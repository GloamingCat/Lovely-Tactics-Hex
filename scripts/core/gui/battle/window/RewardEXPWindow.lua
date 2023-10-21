
-- ================================================================================================

--- The window that shows the gained experience.
---------------------------------------------------------------------------------------------------
-- @classmod RewardEXPWindow

-- ================================================================================================

-- Imports
local PopText = require('core/graphics/PopText')
local SimpleText = require('core/gui/widget/SimpleText')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

-- Class table.
local RewardEXPWindow = class(Window)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Window:createContent`. 
-- @override
function RewardEXPWindow:createContent(...)
  Window.createContent(self, ...)
  self.done = false
  local font = Fonts.gui_medium
  local x = - self.width / 2 + self:paddingX()
  local y = - self.height / 2 + self:paddingY()
  local w = self.width - self:paddingX() * 2
  local title = SimpleText(Vocab.experience, Vector(x, y), w, 'center')
  title:setTerm('experience', '')
  title:redraw()
  self.content:add(title)
  y = y + 20
  for _, member in ipairs(self.GUI.troop.members) do
    local v = self.GUI.rewards.exp[member.key]
    if v then
      local battler = self.GUI.troop.battlers[member.key]
      -- Name
      local posName = Vector(x, y)
      local name = SimpleText('', posName, w / 2, 'left', font)
      name:setTerm('data.battler.' .. battler.key, battler.name)
      name:redraw()
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
  end
  self.soundPeriod = 5
  self.expSound = Config.sounds.exp
  self.expSpeed = 120
  self.levelupSound = Config.sounds.levelup
end

-- ------------------------------------------------------------------------------------------------
-- EXP Gain
-- ------------------------------------------------------------------------------------------------

--- Show EXP gain.
-- @coroutine addEXP
function RewardEXPWindow:addEXP()
  local done, levelup, changed
  local soundTime = self.soundPeriod
  repeat
    done, levelup, changed = true, false, false
    for i = 4, #self.content, 4 do
      local exp1 = self.content[i] -- Current exp
      local exp2 = self.content[i + 1] -- Exp to gain
      local job = exp1.battler.job
      if exp2.value > 0 then
        done = false
        local gain = math.min(self.expSpeed * GameManager:frameTime(), exp2.value)
        exp1.value = exp1.value + gain
        gain = math.floor(exp1.value - job.exp)
        if gain > 0 then
          changed = true
          local nextLevel = job:levelsup(gain)
          -- Level-up
          if nextLevel then
            local x = self:paddingX() - self.width / 2
            local y = exp1.position.y + 8
            local popText = PopText(x, y + 10, GUIManager.renderer)
            popText:addLine('Level ' .. nextLevel .. '!', 'popup_levelup', 'popup_levelup')
            popText:popUp()
            levelup = true
          end
          job:addExperience(gain)
          exp1.value = job.exp
          exp2.value = exp2.value - gain
          exp1:setText('' .. exp1.value)
          exp1:redraw()
          exp2:setText('' .. exp2.value)
          exp2:redraw()
        end
      end
    end
    soundTime = soundTime + GameManager:frameTime() * 60
    if self.expSound and soundTime >= self.soundPeriod and changed then
      soundTime = soundTime - self.soundPeriod
      AudioManager:playSFX(self.expSound)
    end
    if levelup and self.levelupSound then
      AudioManager:playSFX(self.levelupSound)
    end
    Fiber:wait()
  until done
end
--- Overrides `Window:onConfirm`. 
-- @override
function RewardEXPWindow:onConfirm()
  AudioManager:playSFX(Config.sounds.buttonConfirm)
  if self.done then
    self.result = 1
    self.fiber:interrupt()
    return
  end
  self.done = true
  self.fiber = GUIManager.fiberList:fork(self.addEXP, self)
end
--- Overrides `Window:onCancel`. 
-- @override
function RewardEXPWindow:onCancel()
  self:onConfirm()
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

-- @treturn string String representation (for debugging).
function RewardEXPWindow:__tostring()
  return 'EXP Reward Window'
end

return RewardEXPWindow
