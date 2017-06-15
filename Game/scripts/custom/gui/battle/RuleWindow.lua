
--[[===============================================================================================

RuleWindow
---------------------------------------------------------------------------------------------------
Window that opens when creating the battle database to manually decide a rule.

=================================================================================================]]

-- Imports
local ActionWindow = require('custom/gui/battle/ActionWindow')
local MoveAction = require('core/battle/action/MoveAction')
local EscapeAction = require('core/battle/action/EscapeAction')
local VisualizeAction = require('core/battle/action/VisualizeAction')
local CallAction = require('core/battle/action/CallAction')
local TradeSkill = require('custom/skill/TradeSkill')
local BattleCursor = require('core/battle/BattleCursor')

-- Alias
local mathf = math.field

local RuleWindow = class(ActionWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides ButtonWindow:createButtons.
function RuleWindow:createButtons()
  self.ai = BattleManager.currentCharacter.battler.ai
  for
  self:addButton('Attack', nil, self.onAttackAction, self.attackEnabled)
  self.userCursor = BattleCursor()
  self.content:add(self.userCursor)
end

---------------------------------------------------------------------------------------------------
-- Confirm callbacks
---------------------------------------------------------------------------------------------------

-- Selects a rule.
function RuleWindow:onButton(button)
  -- TODO
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

-- String identifier.
function RuleWindow:__tostring()
  return 'RuleWindow'
end

return RuleWindow
