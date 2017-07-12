
--[[===============================================================================================

RuleWindow
---------------------------------------------------------------------------------------------------
Window that opens when creating the battle database to manually decide a rule.

=================================================================================================]]

-- Imports
local ButtonWindow = require('core/gui/ButtonWindow')
local BattleCursor = require('core/battle/BattleCursor')

-- Alias
local mathf = math.field

local RuleWindow = class(ButtonWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

local old_init = RuleWindow.init
function RuleWindow:init(GUI, rules, ...)
  self.rules = rules
  old_init(self, GUI, ...)
end

-- Overrides ButtonWindow:createButtons.
function RuleWindow:createButtons()
  self.ai = BattleManager.currentCharacter.battler.ai
  for i = 1, #self.rules do
    local rule = self.rules[i]
    self:addButton(rule.name, nil, self.onButton)
  end
  self.userCursor = BattleCursor()
  self.content:add(self.userCursor)
end

---------------------------------------------------------------------------------------------------
-- Confirm callbacks
---------------------------------------------------------------------------------------------------

-- Selects a rule.
function RuleWindow:onButton(button)
  --self.GUI:hide()
  self.result = button.index
end

-- Overrides ButtonWindow:onCancel.
function RuleWindow:onCancel()
end

---------------------------------------------------------------------------------------------------
-- General info
---------------------------------------------------------------------------------------------------

-- Overrides ButtonWindow:colCount.
function RuleWindow:colCount()
  return 2
end

-- Overrides ButtonWindow:rowCount.
function RuleWindow:rowCount()
  return 4
end

-- Overrides ButtonWindow:buttonWidth.
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
