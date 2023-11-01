
-- ================================================================================================

--- Changes the initial formation of the battlers.
-- It is executed when players chooses "Formation" in the intro Menu.
---------------------------------------------------------------------------------------------------
-- @battlemod FormationAction
-- @extend CallAction

-- ================================================================================================

-- Imports
local CallAction = require('core/battle/action/CallAction')
local CallMenu = require('core/gui/battle/CallMenu')

-- Class table.
local FormationAction = class(CallAction)

-- ------------------------------------------------------------------------------------------------
-- Input callback
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:onSelect`. 
-- @override
function FormationAction:onSelect(input)
  self.party = input.party or TurnManager.party
  self.troop = TroopManager.troops[self.party]
  CallAction.onSelect(self, input)
end
--- Overrides `FieldAction:onConfirm`. 
-- @override
function FormationAction:onConfirm(input)
  local result = MenuManager:showMenuForResult(CallMenu(input.menu, self.troop, input.user == nil))
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
    input.menu:selectTarget(input.target)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Selectable Tiles
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:isSelectable`. 
-- @override
function FormationAction:isSelectable(input, tile)
  return tile.party == self.party and tile.obstacleList:isEmpty() and
    not FieldManager.currentField:collidesTerrain(tile:coordinates())
end

-- ------------------------------------------------------------------------------------------------
-- Target
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:firstTarget`. 
-- @override
function FormationAction:firstTarget(input)
  local leader = self.troop:currentMembers()[1]
  local char = FieldManager:search(leader.key)
  return char:getTile()
end

return FormationAction
