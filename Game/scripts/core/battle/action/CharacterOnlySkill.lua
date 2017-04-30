
--[[===============================================================================================

CharacterOnlySkill
---------------------------------------------------------------------------------------------------
A special type of Skill that only selects tiles with characters on it.

=================================================================================================]]

-- Imports
local PriorityQueue = require('core/algorithm/PriorityQueue')
local MoveAction = require('core/battle/action/MoveAction')
local SkillAction = require('core/battle/action/SkillAction')
local PathFinder = require('core/algorithm/PathFinder')

local CharacterOnlySkill = class(SkillAction)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:onSelect.
local old_onSelect = CharacterOnlySkill.onSelect
function CharacterOnlySkill:onSelect(user)
  old_onSelect(self, user)
  self.index = 1
  self.selectableTiles = self:getSelectableTiles(user)
end

-- Gets the list of all tiles that have a character.
-- @ret(List) the list of ObjectTiles
function CharacterOnlySkill:getSelectableTiles(user)
  local range = self.data.range
  local moveAction = MoveAction(range)
  local tempQueue = PriorityQueue()
  local initialTile = user:getTile()
  for char in TroopManager.characterList:iterator() do
    local tile = char:getTile()
    if tile.gui.selectable then
      moveAction.currentTarget = tile
      local path = PathFinder.findPath(moveAction, user, initialTile, true)
      if path == nil then
        tempQueue:enqueue(tile, math.huge)
      else
        tempQueue:enqueue(tile, path.totalCost)
      end
    else
      print(tostring(tile))
    end
  end
  return tempQueue:toList()
end

---------------------------------------------------------------------------------------------------
-- Selectable Tiles
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:isSelectable.
function CharacterOnlySkill:isSelectable(tile, user)
  if user.battler.currentSteps == 0 and not tile.gui.reachable then
    return false
  end
  for char in tile.characterList:iterator() do
    if self:isCharacterSelectable(char, user) then
      return true
    end
  end
  return false
end

-- Tells if the given character is selectable.
-- @param(char : Character) the character to check
-- @ret(boolean) true if selectable, false otherwise
function CharacterOnlySkill:isCharacterSelectable(char, user)
  return char.battler:isAlive()
end

---------------------------------------------------------------------------------------------------
-- Grid selecting
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:firstTarget.
function CharacterOnlySkill:firstTarget(user)
  return self.selectableTiles[1]
end

-- Overrides BattleAction:nextTarget.
function CharacterOnlySkill:nextTarget(dx, dy)
  if dx > 0 or dy > 0 then
    if self.index == self.selectableTiles.size then
      self.index = 1
    else
      self.index = self.index + 1
    end
  else
    if self.index == 1 then
      self.index = self.selectableTiles.size
    else
      self.index = self.index - 1
    end
  end
  return self.selectableTiles[self.index]
end

return CharacterOnlySkill
