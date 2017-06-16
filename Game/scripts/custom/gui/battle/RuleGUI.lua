
--[[===============================================================================================

RuleGUI
---------------------------------------------------------------------------------------------------


=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local RuleWindow = require('core/gui/battle/RuleWindow')
local Vector = require('core/math/Vector')

local RuleGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

local old_init = RuleGUI.init
function RuleGUI:init(rules)
  self.rules = rules
  old_init(self)
end

-- Overrides GUI:createWindows.
function RuleGUI:createWindows()
  self.name = 'Rule GUI'
  self.ruleWindow = RuleWindow(self, self.rules)
  self.ruleWindow:setPosition(Vector(-ScreenManager.width / 2 + self.ruleWindow.width / 2 + 8, 
      -ScreenManager.height / 2 + self.ruleWindow.height / 2 + 8))
  self.activeWindow = self.ruleWindow
  self.windowList:add(self.ruleWindow)
end

---------------------------------------------------------------------------------------------------
-- Show
---------------------------------------------------------------------------------------------------

-- Overrides GUI:show.
local old_show = RuleGUI.show
function RuleGUI:show(...)
  FieldManager.renderer:moveToObject(BattleManager.currentCharacter)
  old_show(self, ...)
end

return RuleGUI
