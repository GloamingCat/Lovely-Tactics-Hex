
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
  GUI.init(self)
end

-- Overrides GUI:createWindows.
function RuleGUI:createWindows()
  self.name = 'Rule GUI'
  local ruleWindow = RuleWindow(self, self.rules)
  self.windowList:add(self.ruleWindow)
  self:setActiveWindow(ruleWindow)
end

---------------------------------------------------------------------------------------------------
-- Camera focus
---------------------------------------------------------------------------------------------------

-- Overrides GUI:show.
function RuleGUI:show(...)
  FieldManager.renderer:moveToObject(TurnManager:currentCharacter())
  GUI.show(self, ...)
end

return RuleGUI
