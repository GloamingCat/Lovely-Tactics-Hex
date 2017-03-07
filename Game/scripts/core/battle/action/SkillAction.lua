
local BattleAction = require('core/battle/action/BattleAction')
local isnan = math.isnan
local mathf = math.field

--[[===========================================================================

The BattleAction that is executed when players chooses a skill to use.

=============================================================================]]

local SkillAction = BattleAction:inherit()

local old_init = SkillAction.init
function SkillAction:init(initialTile, user, skill, param)
  old_init(self, initialTile, user)
  self.data = skill
end

-------------------------------------------------------------------------------
-- Selectable Tiles
-------------------------------------------------------------------------------

function SkillAction:resetTargetTiles(selectMovable, selectBorder)
  self:resetAllTiles(false)
  self:resetMovableTiles(selectMovable)
  local matrix = BattleManager.distanceMatrix
  local field = FieldManager.currentField
  local charTile = BattleManager.currentCharacter:getTile()
  local h = charTile.layer.height
  for i = 1, self.field.sizeX do
    for j = 1, self.field.sizeY do
       -- If this tile is reachable
      if not isnan(matrix:get(i, j)) then
        
        local tile = self.field:getObjectTile(i, j, h)
        local isBorder = false
        for neighbor in tile.neighborList:iterator() do
          -- If this tile has any non-reachable neighbors
          if isnan(matrix:get(neighbor.x, neighbor.y)) then
            isBorder = true
            break
          end
        end
        if isBorder then
          for i, j in mathf.radiusIterator(self.data.range + 1, 
              tile.x, tile.y, field.sizeX, field.sizeY) do
            local n = field:getObjectTile(i, j, h) 
            if isnan(matrix:get(n.x, n.y)) then
              n.selectable = selectBorder and self:isSelectable(n)
              n:setColor(self.type)
            end
          end
        end
        
      end
    end
    for i, j in mathf.radiusIterator(self.data.range + 1, 
        charTile.x, charTile.y, field.sizeX, field.sizeY) do
      if isnan(matrix:get(i, j)) then
        local n = field:getObjectTile(i, j, h)
        n.selectable = selectBorder and self:isSelectable(n)
        n:setColor(self.type)
      end
    end
  end
  
end

-------------------------------------------------------------------------------
-- Effect and Animation (TODO)
-------------------------------------------------------------------------------

return SkillAction
