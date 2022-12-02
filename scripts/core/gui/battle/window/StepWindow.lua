
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
  local w, h, m = 80, 30, GUI:windowMargin()
  Window.init(self, GUI, w, h, Vector(ScreenManager.width / 2 - w / 2 - m, 
      ScreenManager.height / 2 - h / 2 - m))
end
-- Overrides Window:createContent.
-- Creates step text.
function StepWindow:createContent(width, height)
  Window.createContent(self, width, height)
  local steps = TurnManager:currentCharacter().battler.steps
  local w = self.width - self:paddingX() * 2
  local h = self.height - self:paddingY() * 2
  local pos = Vector(self:paddingX() - self.width / 2, self:paddingY() - self.height / 2)
  local text = SimpleText('', pos, w)
  text:setTerm('{%steps}:')
  text:redraw()
  local value = SimpleText('' .. steps, pos, w)
  text:setAlign('left', 'center')
  text:setMaxHeight(h)
  value:setAlign('right', 'center')
  value:setMaxHeight(h)
  self.content:add(text)
  self.content:add(value)
end
-- @ret(string) String representation (for debugging).
function StepWindow:__tostring()
  return 'Step Window'
end

return StepWindow
