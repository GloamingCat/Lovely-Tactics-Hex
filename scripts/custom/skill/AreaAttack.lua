
--[[===============================================================================================

AreaAttack
---------------------------------------------------------------------------------------------------
A class for generic area attack skills that targets any tile.

=================================================================================================]]

-- Imports
local SkillAction = require('core/battle/action/SkillAction')

local AreaAttack = class(SkillAction)

---------------------------------------------------------------------------------------------------
-- Grid navigation
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:isSelectable.
function AreaAttack:isSelectable(input, tile)
  return tile.gui.reachable
end

return AreaAttack
