
--[[===============================================================================================

CallRule
---------------------------------------------------------------------------------------------------
The rule for an AI that removes character from battle field.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local AIRule = require('core/battle/ai/AIRule')
local CallAction = require('core/battle/action/CallAction')

local CallRule = class(AIRule)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides AIRule:onSelect.
function CallRule:onSelect(user)
  local troop = TroopManager.troops[user.party]
  local backup = troop:backupMembers()
  self.input = ActionInput(CallAction(), user or TurnManager:currentCharacter())
  self.input.action:onSelect(self.input)
  if backup.size > 0 then
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
      return
    end
  end
  self.input.action = nil
end
-- @ret(string) String identifier.
function CallRule:__tostring()
  return 'CallRule: ' .. self.battler.key
end

return CallRule
