
--[[===============================================================================================

AreaAttack
---------------------------------------------------------------------------------------------------
A class for generic area attack skills that targets any tile.

=================================================================================================]]

-- Imports
local SkillAction = require('core/battle/action/SkillAction')

-- Alias
local radiusIterator = math.field.radiusIterator

local AreaAttack = class(SkillAction)

-- Overrides SkillAction:getAffectedTiles.
function AreaAttack:getAllAffectedTiles(user)
  local tiles = {}
  local field = FieldManager.currentField
  local height = self.currentTarget.layer.height
  local userParty = user.party
  for i, j in radiusIterator(self.data.radius - 1,  
      self.currentTarget.x, self.currentTarget.y) do
    if i >= 1 and j >= 0 and i <= field.sizeX and j <= field.sizeY then
      local tile = field:getObjectTile(i, j, height)
      if tile:hasEnemy(userParty) then
        tiles[#tiles + 1] = tile
      end
    end
  end
  return tiles
end

return AreaAttack
