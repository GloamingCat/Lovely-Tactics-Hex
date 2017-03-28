
--[[===========================================================================

VisualizeAction
-------------------------------------------------------------------------------
The BattleAction that is executed when players cancels in the Turn Window.

=============================================================================]]

-- Imports
local BattleAction = require('core/battle/action/BattleAction')

local VisualizeAction = BattleAction:inherit()

-------------------------------------------------------------------------------
-- Event handlers
-------------------------------------------------------------------------------

-- Overrides BattleAction:onConfirm.
function VisualizeAction:onConfirm()
end

-------------------------------------------------------------------------------
-- Selectable Tiles
-------------------------------------------------------------------------------

-- Overrides BattleAction:isSelectable.
function VisualizeAction:isSelectable(tile)
  return not tile.characterList:isEmpty()
end

-------------------------------------------------------------------------------
-- Grid navigation
-------------------------------------------------------------------------------

-- Overrides BattleAction:selectTarget.
local old_selectTarget = VisualizeAction.selectTarget
function VisualizeAction:selectTarget(tile)
  old_selectTarget(self, tile)
  -- TODO: show stat window
end

return VisualizeAction
