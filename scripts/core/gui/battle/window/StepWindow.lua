
--[[===============================================================================================

StepWindow
---------------------------------------------------------------------------------------------------
Window that opens in Action GUI to show current character's number of 
remaining steps.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')
local SimpleText = require('core/gui/widget/SimpleText')

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
-- Creates step text.
function StepWindow:createContent(width, height)
  Window.createContent(self, width, height)
  local steps = TurnManager:currentCharacter().steps
  local w = self.width - self:paddingX() * 2
  local pos = Vector(self:paddingX() - self.width / 2, self:paddingY() - self.height / 2 - 3)
  local text = SimpleText(Vocab.steps .. ':', pos, w)
  local value = SimpleText('' .. steps, pos, w, 'right')
  self.content:add(text)
  self.content:add(value)
end
-- @ret(string) String representation (for debugging).
function StepWindow:__tostring()
  return 'Step Window'
end

return StepWindow
