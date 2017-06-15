
--[[===============================================================================================

RuleGUI
---------------------------------------------------------------------------------------------------


=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local TurnWindow = require('custom/gui/battle/TurnWindow')
local SkillWindow = require('custom/gui/battle/SkillWindow')
local ItemWindow = require('custom/gui/battle/ItemWindow')
local Vector = require('core/math/Vector')

local RuleGUI = class(GUI)

function RuleGUI:init(user)
  local rules = user.battler.AI.rules
  
end

function RuleGUI:createWindows()
  self.name = 'Rule GUI'

  self.turnWindow = TurnWindow(self)
  self.turnWindow:setPosition(Vector(-ScreenManager.width / 2 + self.turnWindow.width / 2 + 8, 
      -ScreenManager.height / 2 + self.turnWindow.height / 2 + 8))
  
  self.activeWindow = self.turnWindow
  self.windowList:add(self.turnWindow)
end

-- Overrides GUI:show.
local old_show = RuleGUI.show
function RuleGUI:show(...)
  FieldManager.renderer:moveToObject(BattleManager.currentCharacter)
  old_show(self, ...)
end

return RuleGUI
