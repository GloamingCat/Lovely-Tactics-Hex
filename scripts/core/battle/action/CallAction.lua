
--[[===============================================================================================

CallAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players chooses the "Call Ally" button.

=================================================================================================]]

-- Imports
local BattleAction = require('core/battle/action/BattleAction')

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
    local result = GUIManager:showGUIForResult('battle/CallGUI', input.target)
    if result ~= 0 then
      TroopManager:createBattleCharacter(input.target, result)
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
  return tile.gui.party == input.user.battler.party and not tile:collides(0, 0)
end

return CallAction
