
--[[===============================================================================================

ControlZone
---------------------------------------------------------------------------------------------------


=================================================================================================]]

-- Imports
local MoveAction = require('core/battle/action/MoveAction')
local ObjectTile = require('core/field/ObjectTile')

---------------------------------------------------------------------------------------------------
-- MoveAction
---------------------------------------------------------------------------------------------------

-- Override.
local old_passable = MoveAction.isPassableBetween
function MoveAction:isPassableBetween(initial, final, user)
  local passable = old_passable(self, initial, final, user)
  return passable and initial:isControlZone(user.battler)
end

---------------------------------------------------------------------------------------------------
-- ObjectTile
---------------------------------------------------------------------------------------------------

-- Checks if this tile os in control zone for given party.
-- @param(you : Battler) the battler of the current character
-- @ret(boolean) true if it's control zone, false otherwise
function ObjectTile:isControlZone(you, noneighbours)
  local containsAlly, containsEnemy = false, false
  for char in self.characterList:iterator() do
    if char.battler and char.battler:isAlive() then
      if char.battler.party == you.party then
        containsAlly = true
      else
        containsEnemy = true
      end
    end
  end
  if containsEnemy then
    return true
  elseif containsAlly then
    return false
  end
  if noneighbours then
    return false
  end
  for n in self.neighborList:iterator() do
    if n:isControlZone(you, true) then
      return true
    end
  end
  return false
end
