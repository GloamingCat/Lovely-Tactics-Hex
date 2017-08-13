
--[[===============================================================================================

CharacterOnlySkill
---------------------------------------------------------------------------------------------------
A special type of Skill that only selects tiles with characters on it.

=================================================================================================]]

-- Imports
local MoveAction = require('core/battle/action/MoveAction')
local SkillAction = require('core/battle/action/SkillAction')
local BattleTactics = require('core/battle/ai/BattleTactics')

local CharacterOnlySkill = class(SkillAction)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:onSelect.
function CharacterOnlySkill:onSelect(input)
  SkillAction.onSelect(self, input)
  if input.GUI then
    self.index = 1
    self.selectableTiles = self:getSelectableTiles(input)
  end
end
-- Gets the list of all tiles that have a character.
-- @ret(List) the list of ObjectTiles
function CharacterOnlySkill:getSelectableTiles(input)
  local queue = BattleTactics.closestCharacters(input)
  return queue:toList()
end

---------------------------------------------------------------------------------------------------
-- Selectable Tiles
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:isSelectable.
function CharacterOnlySkill:isSelectable(input, tile)
  if input.user.battler.steps == 0 and not tile.gui.reachable then
    return false
  end
  for char in tile.characterList:iterator() do
    if self:isCharacterSelectable(input, char) then
      return true
    end
  end
  return false
end
-- Tells if the given character is selectable.
-- @param(char : Character) the character to check
-- @ret(boolean) true if selectable, false otherwise
function CharacterOnlySkill:isCharacterSelectable(input, char)
  return char.battler:isAlive()
end

---------------------------------------------------------------------------------------------------
-- Grid selecting
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:firstTarget.
function CharacterOnlySkill:firstTarget(input)
  return self.selectableTiles[1]
end
-- Overrides BattleAction:nextTarget.
function CharacterOnlySkill:nextTarget(input, dx, dy)
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
