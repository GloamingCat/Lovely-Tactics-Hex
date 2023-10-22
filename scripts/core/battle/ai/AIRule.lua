
-- ================================================================================================

--- A rule that decides a character's action in a battle turn.
-- It doesn't have a persistent state of its own and only keeps data that are independent from th
-- current battle state. Instead of storing state-dependent data, it generates in run time the
-- ActionInput to be used according to the state.
---------------------------------------------------------------------------------------------------
-- @battlemod AIRule

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')

-- Alias
local rand = love.math.random

-- Class table.
local AIRule = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Battler battler The battler executing this rule.
-- @tparam string condition The condition expression that decides if this rule should be executed now.
-- @tparam table tags Array of tag entries.
function AIRule:init(battler, condition, tags)
  self.battler = battler
  self.condition = condition
  self.tags = Database.loadTags(tags)
  self.input = nil
end
--- Creates an AIRule from the given rule data.
-- @tparam table data Rule data with path, param and condition fields.
-- @tparam Battler battler The battler executing this rule.
-- @treturn AIRule
function AIRule:fromData(data, battler)
  local class = self
  if data.name and data.name ~= '' then
    class = require('custom/' .. data.name)
  end
  return class(battler, data.condition, data.tags)
end

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Checks if a rule can be executed.
-- @treturn boolean
function AIRule:canExecute()
  return self.input and self.input:canExecute()
end
--- Executes the rule.
-- @treturn table The action result table.
function AIRule:execute()
  return self.input and self.input:execute()
end

-- ------------------------------------------------------------------------------------------------
-- Auxiliary
-- ------------------------------------------------------------------------------------------------

--- Randomly returns true with a given chance.
-- @tparam number percent Chance from 0 to 100.
-- @treturn boolean
function AIRule:chance(percent)
  return rand() * 100 < percent 
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Prepares the rule to be executed (or not, if it's not possible).
-- @tparam Character user
function AIRule:onSelect(user)
end
-- For debugging.
function AIRule:__tostring()
  return 'AIRule: ' .. self.battler.key
end

return AIRule
