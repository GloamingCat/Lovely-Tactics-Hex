
-- ================================================================================================

--- Implements basic functions to be used in AI classes.
---------------------------------------------------------------------------------------------------
-- @battlemod BattlerAI

-- ================================================================================================

-- Imports
local AIRule = require('core/battle/ai/AIRule')
local BattleAction = require('core/battle/action/BattleAction')
local BattleCursor = require('core/battle/BattleCursor')

-- Class table.
local BattlerAI = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Battler battler The battler with this AI.
-- @tparam table rules The list of data tables for each AI rule.
function BattlerAI:init(battler, rules)
  self.battler = battler
  self.rules = rules
end

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Executes next action of the current character, when it's the character's turn.
-- By default, just skips turn, with no time loss.
-- @treturn TurnManager.ActionResult The action result table.
function BattlerAI:runTurn()
  local char = TurnManager:currentCharacter()
  self:showCursor(char)
  local result = self:applyRules(char)
  return result
end
--- Executes the rules in order until one of them produces a result.
-- If none of the rules can be executed, it returns a result equivalent of a "wait" action.
-- @tparam Character char The battle character executing the rules.
-- @treturn TurnManager.ActionResult The action result table.
function BattlerAI:applyRules(char)
  for i = 1, #self.rules do
    local rule = AIRule:fromData(self.rules[i], self.battler)
    rule:onSelect(char)
    local condition = rule.condition ~= '' and rule.condition
    if not condition or self:decodeCondition(rule, condition, char) then
      if rule:canExecute() then
        local result = rule:execute()
        if result.endCharacterTurn or result.endTurn then
          return result
        end
      end
    end
  end
  return BattleAction():execute({})
end
--- Evaluates a given expression.
-- @tparam ActionRule rule Argument passed to the condition.
-- @tparam string condition Boolean expression.
-- @tparam Character char The character executing this script.
-- @treturn boolean The value of the expression.
function BattlerAI:decodeCondition(rule, condition, ...)
  return loadformula(condition, 'self, AI, user')(rule, self, ...)
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Shows the cursor over a character.
-- @coroutine
-- @tparam Character char The character the cursor will point to.
-- @tparam[opt=30] The time in frames to wait.
function BattlerAI:showCursor(char, time)
  FieldManager.renderer:moveToObject(char, nil, true)
  local cursor = BattleCursor()
  cursor:setTile(char:getTile())
  cursor:show()
  FieldManager.updateList:add(cursor)
  Fiber:wait(30)
  FieldManager.updateList:removeElement(cursor)
  cursor:destroy()
end
-- For debugging.
function BattlerAI:__tostring()
  return 'BattlerAI: ' .. self.battler.key
end

return BattlerAI
