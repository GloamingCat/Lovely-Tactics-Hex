
--[[===========================================================================

VisualizeAction
-------------------------------------------------------------------------------
The BattleAction that is executed when players cancels in the Turn Window.

=============================================================================]]

-- Imports
local BattlerWindow = require('custom/gui/battle/BattlerWindow')
local BattleAction = require('core/battle/action/BattleAction')

local VisualizeAction = class(BattleAction)

-------------------------------------------------------------------------------
-- Event handlers
-------------------------------------------------------------------------------

-- Overrides BattleAction:onConfirm.
function VisualizeAction:onConfirm(user)
  -- TODO: show BattlerWindow
end

-- Overrides BattleAction:onActionGUI.
function BattleAction:onActionGUI(GUI, user)
  self:resetAllTiles(false)
  GUI:createTargetWindow()
  GUI:startGridSelecting(self:firstTarget(user))
end

-------------------------------------------------------------------------------
-- Selectable Tiles
-------------------------------------------------------------------------------

-- Overrides BattleAction:isSelectable.
function VisualizeAction:isSelectable(tile, user)
  return not tile.characterList:isEmpty()
end

return VisualizeAction
