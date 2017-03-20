
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Window = require('core/gui/Window')
local SimpleText = require('core/gui/SimpleText')
local BattlePortrait = require('custom/gui/battle/BattlePortrait')
local attConfig = Config.attributes
local max = math.max

--[[===========================================================================

Window that shows on each character in the VisualizeAction.

=============================================================================]]

local AttributeWindow = Window:inherit()

-- Overrides Window:init.
local old_init = AttributeWindow.init
function AttributeWindow:init(GUI, skin)
  old_init(self, GUI, 100, , Vector(ScreenManager.width / 2 - 40, 
      -ScreenManager.height / 2 + 20), skin)
end

-- Overrides Window:createContent.
local old_createContent = AttributeWindow.createContent
function AttributeWindow:createContent()
  old_createContent(self)
  local battler = BattleManager.currentAction.currentTarget.characterList[1].battler
  self.portrait = BattlePortrait(battler)
  
  local lineCount = 0
  
  for i = 1, #attConfig do
    local att = attConfig[i]
    if att.script == '' then
      local str1 = att.shortName .. ': ' .. att[att.shortName]()
      local text = SimpleText(str1)
      lineCount = lineCount + 1
    end
  end
  self.width = self.paddingw * 2 + 100
  self.height = max(lineCount * 20, self.portrait:getHeight()) + self.paddingh * 2
  old_createContent(self)
end

return AttributeWindow
