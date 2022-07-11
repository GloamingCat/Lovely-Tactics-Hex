
--[[===============================================================================================

VisualizeAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players cancels in the Turn Window.

=================================================================================================]]

-- Imports
local BattleAction = require('core/battle/action/BattleAction')
local VisualizeGUI = require('core/gui/battle/VisualizeGUI')

local VisualizeAction = class(BattleAction)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function VisualizeAction:init()
  BattleAction.init(self, '')
  self.allTiles = true
end

---------------------------------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:execute.
function VisualizeAction:execute(input)
  local character = input.target:getFirstBattleCharacter()
  GUIManager:showGUIForResult(VisualizeGUI(input.GUI, character))
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
  for tile in self.field:gridIterator() do
    tile.gui:setColor('')
  end
end

---------------------------------------------------------------------------------------------------
-- Selectable Tiles
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:isSelectable.
function VisualizeAction:isSelectable(input, tile)
  return tile:getFirstBattleCharacter() ~= nil
end

return VisualizeAction
