
--[[===============================================================================================

CallRule
---------------------------------------------------------------------------------------------------
The rule for an AI that removes character from battle field.

-- Parameters:
The <member> as a boolean formula to only consider the members that satifies it. 
Set <reset> as true to discard any saved changes on the called member.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local AIRule = require('core/battle/ai/AIRule')
local CallAction = require('core/battle/action/CallAction')

local CallRule = class(AIRule)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(...) AIRule constructor arguments.
function CallRule:init(...)
  AIRule.init(self, ...)
  if self.tags and self.tags.member then
    self.memberCondition = loadformula('not (' .. self.tags.member .. ')', 'member')
  end
end
-- Overrides AIRule:onSelect.
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
-- @ret(string) String identifier.
function CallRule:__tostring()
  return 'CallRule: ' .. self.battler.key
end

return CallRule
