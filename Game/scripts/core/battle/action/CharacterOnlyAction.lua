
local PriorityQueue = require('core/algorithm/PriorityQueue')
local MoveAction = require('core/battle/action/MoveAction')
local SkillAction = require('core/battle/action/SkillAction')
local SkillMoveAction = require('core/battle/action/SkillMoveAction')
local PathFinder = require('core/algorithm/PathFinder')

--[[===========================================================================



=============================================================================]]

local CharacterOnlyAction = SkillAction:inherit()

function CharacterOnlyAction:onActionGUI(GUI)
  self:resetAllTiles(false)
  self:resetTargetTiles(false, false)
  self:resetCharacterTiles()
  self.index = 1
  GUI:startGridSelecting(self:firstTarget())
end

function CharacterOnlyAction:isSelectable(tile)
  for _, char in tile.characterList:iterator() do
    if self:isCharacterSelectable(char) then
      return true
    end
  end
  return false
end

function CharacterOnlyAction:resetCharacterTiles()
  if not self.selectableTiles then
    local moveAction = SkillMoveAction(self.data.range, self.currentTarget, self.user)
    local tempQueue = PriorityQueue()
    for _, char in TroopManager.characterList:iterator() do
      if self:isCharacterSelectable(char) then
        print(char:toString())
        local tile = char:getTile()
        moveAction.currentTarget = tile
        local path = PathFinder.findPath(moveAction, nil, true)
        if path == nil then
          tempQueue:enqueue(tile, math.huge)
        else
          tempQueue:enqueue(tile, path.totalCost)
        end
      end
    end
    self.selectableTiles = tempQueue:toList()
  end
  for i = 1, self.selectableTiles.size do
    local t = self.selectableTiles[i]
    t.selectable = true
    t:setColor(t.colorName)
  end
end

-- Tells if the given character is selectable.
function CharacterOnlyAction:isCharacterSelectable(char)
  return true
end

-- Overrides BattleAction:firstTarget.
function CharacterOnlyAction:firstTarget()
  return self.selectableTiles[1]
end

-- Overrides BattleAction:nextTarget.
function CharacterOnlyAction:nextTarget(dx, dy)
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

return CharacterOnlyAction
