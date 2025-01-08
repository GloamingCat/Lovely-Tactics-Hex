
-- ================================================================================================

--- Navigates around the field to check battlers' attributes.
-- It is executed when players chooses the "Inspect" button during battle.
---------------------------------------------------------------------------------------------------
-- @battlemod VisualizeAction
-- @extend BattleAction

-- ================================================================================================

-- Imports
local BattleAction = require('core/battle/action/BattleAction')
local VisualizeMenu = require('core/gui/battle/VisualizeMenu')

-- Class table.
local VisualizeAction = class(BattleAction)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function VisualizeAction:init()
  BattleAction.init(self, '')
  self.freeNavigation = true
  self.autoPath = false
  self.reachableOnly = false
  self.affectedOnly = true
  self.allParties = true
end

-- ------------------------------------------------------------------------------------------------
-- Event handlers
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:execute`. 
-- @override
function VisualizeAction:execute(input)
  local character = input.target:getFirstBattleCharacter()
  FieldManager.renderer:moveToTile(input.target)
  MenuManager:showMenuForResult(VisualizeMenu(input.menu, character))
  if input.menu then
    input.menu:startGridSelecting(input.target)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Tile Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:resetTileColors`. 
-- @override
function VisualizeAction:resetTileColors(input)
  for tile in self.field:gridIterator() do
    tile.ui:setColor('')
  end
end

-- ------------------------------------------------------------------------------------------------
-- Selectable Tiles
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:isSelectable`. 
-- @override
function VisualizeAction:isSelectable(input, tile)
  return tile:getFirstBattleCharacter() ~= nil
end

return VisualizeAction
