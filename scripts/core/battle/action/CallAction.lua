
--[[===============================================================================================

CallAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players chooses the "Call Ally" button.

=================================================================================================]]

-- Imports
local BattleAction = require('core/battle/action/BattleAction')
local CallGUI = require('core/gui/battle/CallGUI')

local CallAction = class(BattleAction)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function CallAction:init()
  BattleAction.init(self, 0, 1, 'general')
  self.showTargetWindow = false
end

---------------------------------------------------------------------------------------------------
-- Input callback
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:onConfirm.
function CallAction:onConfirm(input)
  if input.GUI then
    local troop = TurnManager:currentTroop()
    local result = GUIManager:showGUIForResult(CallGUI(troop))
    if result ~= 0 then
      troop:callMember(result, input.target)
      input.GUI:endGridSelecting()
      return self:execute()
    end
  end
  return nil
end

---------------------------------------------------------------------------------------------------
-- Tile Properties
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:resetTileProperties.
function CallAction:resetTileProperties(input)
  self:resetSelectableTiles(input)
end
-- Overrides BattleAction:resetTileColors.
function CallAction:resetTileColors(input)
  for tile in self.field:gridIterator() do
    if tile.gui.selectable then
      tile.gui:setColor(self.colorName)
    else
      tile.gui:setColor('')
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Selectable Tiles
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:isSelectable.
function CallAction:isSelectable(input, tile)
  return tile.party == input.user.battler.party and not tile:collides(0, 0)
end

return CallAction
