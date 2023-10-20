
-- ================================================================================================

--- The rule for an AI that calls another character to the battle field.
---------------------------------------------------------------------------------------------------
-- @classmod CallRule

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local AIRule = require('core/battle/ai/AIRule')
local CallAction = require('core/battle/action/CallAction')

-- Class table.
local CallRule = class(AIRule)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @param ...  AIRule constructor arguments.
function CallRule:init(...)
  AIRule.init(self, ...)
  --- Contains the tags from the Battler's rules data.
  -- @table param
  -- @tfield string member A boolean formula to only consider the members that satifies it. 
  -- @tfield boolean reset Flag to discard any saved changes on the called member.
  local param = self.tags
  if param and param.member then
    self.memberCondition = loadformula('not (' .. param.member .. ')', 'member')
  end
end
--- Overrides `AIRule:onSelect`. 
-- @override onSelect
function CallRule:onSelect(user)
  local troop = TroopManager.troops[user.party]
  local backup = troop:backupBattlers()
  if self.memberCondition then
    backup:conditionalRemove(self.memberCondition)
  end
  if backup.size > 0 then
    self.input = ActionInput(CallAction(), user or TurnManager:currentCharacter())
    self.input.action.resetBattler = self.tags and self.tags.reset
    self.input.action:onSelect(self.input)
    local validTiles = 0
    for tile in FieldManager.currentField:gridIterator() do
      if tile.gui.selectable then
        validTiles = validTiles + 1
        if love.math.random(validTiles) == 1 then
          self.input.target = tile
        end
      end
    end
    if self.input.target then
      self.input.member = backup[1].key
    else
      self.input = nil
    end
  end
end
--- String identifier.
-- @treturn string
function CallRule:__tostring()
  return 'CallRule: ' .. self.battler.key
end

return CallRule
