
--[[===========================================================================

VisualizeAction
-------------------------------------------------------------------------------
The BattleAction that is executed when players cancels in the Turn Window.

=============================================================================]]

-- Imports
local BattlerWindow = require('custom/gui/battle/BattlerWindow')
local BattleAction = require('core/battle/action/BattleAction')

local VisualizeAction = BattleAction:inherit()

-------------------------------------------------------------------------------
-- Event handlers
-------------------------------------------------------------------------------

-- Overrides BattleAction:onConfirm.
function VisualizeAction:onConfirm()
  -- TODO: show BattlerWindow
end

-- Overrides BattleAction:onActionGUI.
function BattleAction:onActionGUI(GUI)
  self:resetAllTiles(false)
  GUI:createTargetWindow()
  GUI:startGridSelecting(self:firstTarget())
end

-------------------------------------------------------------------------------
-- Selectable Tiles
-------------------------------------------------------------------------------

-- Overrides BattleAction:isSelectable.
function VisualizeAction:isSelectable(tile)
  return not tile.characterList:isEmpty()
end

return VisualizeAction
