
--[[===============================================================================================

RuleWindow
---------------------------------------------------------------------------------------------------
Window that opens when creating the battle database to manually decide a rule.

=================================================================================================]]

-- Imports
local GridWindow = require('core/gui/GridWindow')
local BattleCursor = require('core/battle/BattleCursor')
local Button = require('core/gui/Button')

-- Alias
local mathf = math.field

local RuleWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

local old_init = RuleWindow.init
function RuleWindow:init(GUI, rules, ...)
  self.rules = rules
  old_init(self, GUI, ...)
end

-- Overrides GridWindow:createButtons.
function RuleWindow:createButtons()
  self.ai = BattleManager.currentCharacter.battler.ai
  for i = 1, #self.rules do
    local rule = self.rules[i]
    Button(self, rule.name, nil, self.onButton)
  end
  self.userCursor = BattleCursor()
  self.content:add(self.userCursor)
end

---------------------------------------------------------------------------------------------------
-- Confirm callbacks
---------------------------------------------------------------------------------------------------

-- Selects a rule.
function RuleWindow:onButton(button)
  self.result = button.index
end

-- Overrides GridWindow:onCancel.
function RuleWindow:onCancel()
end

---------------------------------------------------------------------------------------------------
-- General info
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function RuleWindow:colCount()
  return 2
end

-- Overrides GridWindow:rowCount.
function RuleWindow:rowCount()
  return 4
end

-- Overrides GridWindow:buttonWidth.
function RuleWindow:buttonWidth()
  return 100
end

---------------------------------------------------------------------------------------------------
-- Battle Cursor
---------------------------------------------------------------------------------------------------

-- Overrides Window:show.
local old_show = RuleWindow.show
function RuleWindow:show(add)
  local user = BattleManager.currentCharacter
  self.userCursor:setCharacter(user)
  old_show(self, add)
end

-- String identifier.
function RuleWindow:__tostring()
  return 'RuleWindow'
end

return RuleWindow
