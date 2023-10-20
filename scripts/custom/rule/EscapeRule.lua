
-- ================================================================================================

--- The rule for an AI that removes character from battle field. If not possible to execute,
-- it moves the character to the closest party tile.
---------------------------------------------------------------------------------------------------
-- @classmod EscapeRule

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local AIRule = require('core/battle/ai/AIRule')
local EscapeAction = require('core/battle/action/EscapeAction')

-- Class table.
local EscapeRule = class(AIRule)

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Overrides `AIRule:onSelect`. 
-- @override onSelect
function EscapeRule:onSelect(user)
  --- Contains the tags from the Battler's rules data.
  -- @table param
  -- @tfield boolean hide Flag to make the battler unable to be called again into battle.
  user = user or TurnManager:currentCharacter()
  self.input = ActionInput(EscapeAction(true), user)
  self.input.action.hide = self.tags and self.tags.hide
  self.input.action:onSelect(self.input)
end
--- String identifier.
-- @treturn string
function EscapeRule:__tostring()
  return 'EscapeRule: ' .. self.battler.key
end

return EscapeRule
