
--[[===============================================================================================

VisualizeAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players cancels in the Turn Window.

=================================================================================================]]

-- Imports
local BattlerWindow = require('core/gui/battle/BattlerWindow')
local BattleAction = require('core/battle/action/BattleAction')

local VisualizeAction = class(BattleAction)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

local old_init = VisualizeAction.init
function VisualizeAction:init()
  old_init(self, nil, 0, 1)
end

---------------------------------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:onConfirm.
function VisualizeAction:onConfirm(input)
  -- TODO: show BattlerWindow
end

---------------------------------------------------------------------------------------------------
-- Tile Properties
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:resetTileProperties.
function VisualizeAction:resetTileProperties(input)
  self:resetSelectableTiles(input)
end

-- Overrides BattleAction:resetTileColors.
function VisualizeAction:resetTileColors(input)
  self:clearTileColors()
end

---------------------------------------------------------------------------------------------------
-- Selectable Tiles
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:isSelectable.
function VisualizeAction:isSelectable(input, tile)
  return not tile.characterList:isEmpty()
end

return VisualizeAction
