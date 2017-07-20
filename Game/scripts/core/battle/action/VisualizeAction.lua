
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

-- Constructor.
function VisualizeAction:init()
  BattleAction.init(self, nil, 0, 1)
end

---------------------------------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:execute.
function VisualizeAction:execute(input)
  local character = input.target.characterList[1]
  GUIManager:showGUIForResult('battle/VisualizeGUI', character)
  if input.GUI then
    input.GUI:startGridSelecting(input.target)
  end
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
