
--[[===============================================================================================

FormationAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players chooses "Formation" in the intro GUI.

=================================================================================================]]

-- Imports
local CallAction = require('core/battle/action/CallAction')
local CallGUI = require('core/gui/battle/CallGUI')

local FormationAction = class(CallAction)

---------------------------------------------------------------------------------------------------
-- Input callback
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:onConfirm.
function FormationAction:onConfirm(input)
  self.troop = TroopManager.troops[(input.party or TurnManager.party)]
  local result = GUIManager:showGUIForResult(CallGUI(input.GUI, self.troop, input.user == nil))
  if result ~= 0 then
    local char = input.target:getFirstBattleCharacter()
    if result == '' then
      if char then
        self:removeMember(char)
      else
        return nil
      end
    else
      if char and char.key ~= result then
        self:removeMember(char)
      end
      char = FieldManager:search(result)
      if char then
        char:removeFromTiles()
        char:moveToTile(input.target)
        char:addToTiles()
      else
        self:callMember(result, input.target)
      end
    end
    TroopManager.centers = TroopManager:getPartyCenters()
    self:resetTileProperties(input)
    self:resetTileColors(input)
    input.GUI:selectTarget(input.target)
  end
end

---------------------------------------------------------------------------------------------------
-- Selectable Tiles
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:isSelectable.
function FormationAction:isSelectable(input, tile)
  return tile.party == TurnManager.party and tile.obstacleList:isEmpty() and
    not FieldManager.currentField:collidesTerrain(tile:coordinates())
end

---------------------------------------------------------------------------------------------------
-- Target
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:firstTarget.
function FormationAction:firstTarget(input)
  local leader = TurnManager:currentTroop():currentMembers()[1]
  local char = FieldManager:search(leader.key)
  return char:getTile()
end

return FormationAction
