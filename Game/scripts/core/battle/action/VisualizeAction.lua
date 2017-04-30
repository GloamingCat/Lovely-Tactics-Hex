
--[[===============================================================================================

VisualizeAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players cancels in the Turn Window.

=================================================================================================]]

-- Imports
local BattlerWindow = require('custom/gui/battle/BattlerWindow')
local BattleAction = require('core/battle/action/BattleAction')

local VisualizeAction = class(BattleAction)

---------------------------------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:onConfirm.
function VisualizeAction:onConfirm(user)
  -- TODO: show BattlerWindow
end

---------------------------------------------------------------------------------------------------
-- Tile Properties
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:resetTileProperties.
function VisualizeAction:resetTileProperties(user)
  self:resetSelectableTiles(user)
end

function VisualizeAction:resetTileColors(user)
  self:clearTileColors()
end

---------------------------------------------------------------------------------------------------
-- Selectable Tiles
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:isSelectable.
function VisualizeAction:isSelectable(tile, user)
  return not tile.characterList:isEmpty()
end

return VisualizeAction
