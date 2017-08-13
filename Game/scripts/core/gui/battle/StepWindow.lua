
--[[===============================================================================================

StepWindow
---------------------------------------------------------------------------------------------------
Window that opens in Action GUI to show current character's number of 
remaining steps.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')
local SimpleText = require('core/gui/SimpleText')

local StepWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides Window:init.
function StepWindow:init(GUI)
  Window.init(self, GUI, 80, 24, Vector(ScreenManager.width / 2 - 52, 
      ScreenManager.height / 2 - 24))
end
-- Overrides Window:createContent.
function StepWindow:createContent()
  Window.createContent(self)
  local steps = BattleManager.currentCharacter.battler.steps
  local w = self.width - self:hPadding() * 2
  local pos = Vector(self:hPadding() - self.width / 2, self:vpadding() - self.height / 2 - 3)
  local text = SimpleText(Vocab.steps .. ':', pos, w)
  local value = SimpleText('' .. steps, pos, w, 'right')
  self.content:add(text)
  self.content:add(value)
end
-- String identifier.
function StepWindow:__tostring()
  return 'StepWindow'
end

return StepWindow
