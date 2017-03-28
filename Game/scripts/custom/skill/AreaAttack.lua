
--[[===========================================================================

AreaAttack
-------------------------------------------------------------------------------
A class for generic area attack skills that targets enemies.

=============================================================================]]

-- Imports
local SkillAction = require('core/battle/action/SkillAction')

local AreaAttack = SkillAction:inherit()

-- Overrides SkillAction:getAffectedTiles.
function AreaAttack:getAffectedTiles()
  local tiles = {}
  local field = FieldManager.currentField
  local height = self.currentTarget.layer.height
  local userParty = self.user.party
  for i, j in mathf.radiusIterator(self.data.radius, self.currentTarget.x,
      self.currentTarget.y, field.sizeX, field.sizeY) do
    local tile = field:getObjectTile(i, j, height)
    if tile:hasEnemy(userParty) then
      tiles[#tiles + 1] = tile
    end
  end
  return tiles
end

return AreaAttack
