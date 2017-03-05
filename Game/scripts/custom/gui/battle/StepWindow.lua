
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Window = require('core/gui/Window')
local SimpleText = require('core/gui/SimpleText')
local Font = require('custom/Font')
local Vocab = require('custom/Vocab')

--[[===========================================================================

Window that opens in Action GUI.

=============================================================================]]

local StepWindow = Window:inherit()

-- Overrides Window:init.
local old_init = StepWindow.init
function StepWindow:init(GUI, skin)
  old_init(self, GUI, 80, 24, Vector(ScreenManager.width / 2 - 52, 
      ScreenManager.height / 2 - 24), skin)
end

-- Overrides Window:createContent.
local old_createContent = StepWindow.createContent
function StepWindow:createContent()
  old_createContent(self)
  local steps = BattleManager.currentCharacter.battler.currentSteps
  local textPos = Vector(self.paddingw - self.width / 2, self.paddingh - self.height / 2 - 3, -1)
  local text = SimpleText(Vocab.steps .. ':', textPos, 50 - self.paddingw)
  local valuePos = Vector(50 - self.width / 2, self.paddingh - self.height / 2 - 3, -1)
  local value = SimpleText('' .. steps, valuePos, 30 - self.paddingw, nil, 'right')
  self.content:add(text)
  self.content:add(value)
end

return StepWindow
