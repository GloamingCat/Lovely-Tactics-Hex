
-- ================================================================================================

--- A move action that considers information from the battle state.
---------------------------------------------------------------------------------------------------
-- @classmod BattleMoveAction
-- @extend MoveAction

-- ================================================================================================

-- Imports
local MoveAction = require('core/battle/action/MoveAction')
local BattleTactics = require('core/battle/ai/BattleTactics')

-- Alias
local max = math.max
local mathf = math.field

-- Class table.
local BattleMoveAction = class(MoveAction)

-- ------------------------------------------------------------------------------------------------
-- Initalization
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:init`. 
-- @override
function BattleMoveAction:init(...)
  MoveAction.init(self, ...)
  self.freeNavigation = true
  self.showTargetWindow = false
  self.showStepWindow = true
end

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:execute`. 
-- @override
function BattleMoveAction:execute(input)  
  FieldManager.renderer:moveToObject(input.user, nil, true)
  FieldManager.renderer.focusObject = input.user
  local result = MoveAction.execute(self, input)
  input.user.battler:onMove(input.user, result.path)
  TurnManager:updatePathMatrix()
  return result
end
--- Overrides `MoveAction:moveToTile`. 
-- @override
function BattleMoveAction:moveToTile(input, nextTile)
  local previousTiles = input.user:getAllTiles()
  input.user.battler:onTerrainExit(input.user, previousTiles)
  MoveAction.moveToTile(self, input, nextTile)
  input.user.battler:onTerrainEnter(input.user, input.user:getAllTiles())
end
--- Overrides `MoveAction:calculatePath`. 
-- @override
function BattleMoveAction:calculatePath(input)
  local matrix = not self:isRanged() and TurnManager:pathMatrix() or nil
  return input.path or BattleTactics.optimalPath(self, input.user, input.target, matrix)
end

-- ------------------------------------------------------------------------------------------------
-- Selectable Tiles
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:isSelectable`. 
-- @override
function BattleMoveAction:isSelectable(input, tile)
  return tile.gui.movable
end

-- ------------------------------------------------------------------------------------------------
-- Path Finder
-- ------------------------------------------------------------------------------------------------

--- Overrides `MoveAction:isPassableBetween`. 
-- @override
function BattleMoveAction:isPassableBetween(initial, final, user)
  local x, y, h = initial:coordinates()
  local c = self.field:collisionXYZ(user, x, y, h, final:coordinates())
  if c then
    return false
  end
  local maxdh = user.battler.jumpPoints()
  local mindh = -2 * maxdh
  local dh = final.layer.height - h
  return mindh <= dh and dh <= maxdh
end
--- Overrides `MoveAction:getDistanceBetween`. 
-- @override
function BattleMoveAction:getDistanceBetween(initial, final, user)
  return max(initial:getMoveCost(user), final:getMoveCost(user))
end
--- Overrides `MoveAction:maxDistance`. 
-- @override
function BattleMoveAction:maxDistance(user)
  return user.battler.steps or self.pathLimit
end
-- For debugging.
function BattleMoveAction:__tostring()
  if self:isRanged() then
    return "BattleMoveAction ranged"
  else
    return "BattleMoveAction"
  end
end

return BattleMoveAction
