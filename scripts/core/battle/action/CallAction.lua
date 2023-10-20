
-- ================================================================================================

--- Calls an ally from the troop's backup in the battle field.
-- It is executed when players chooses the "Call Ally" button, and also from the `CallRule`.
---------------------------------------------------------------------------------------------------
-- @classmod CallAction

-- ================================================================================================

-- Imports
local BattleAction = require('core/battle/action/BattleAction')
local CallGUI = require('core/gui/battle/CallGUI')

-- Class table.
local CallAction = class(BattleAction)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function CallAction:init()
  BattleAction.init(self, 'general')
  self.showTargetWindow = false
  self.freeNavigation = true
  self.animSpeed = 2
  self.resetBattler = false
end

-- ------------------------------------------------------------------------------------------------
-- Input callback
-- ------------------------------------------------------------------------------------------------

--- Overrides `FieldAction:onConfirm`. 
-- @override onConfirm
function CallAction:onConfirm(input)
  self.troop = TroopManager.troops[(input.party or input.user.party)]
  if input.GUI then
    local result = GUIManager:showGUIForResult(CallGUI(input.GUI, self.troop, input.user == nil))
    if result == 0 then
      return nil
    end
    input.GUI:endGridSelecting()
    input.member = result
  end
  return self:execute(input)
end
--- Overrides `BattleAction:execute`. 
-- @override execute
function CallAction:execute(input)
  self:callMember(input.member, input.target, true)
  return BattleAction.execute(self, input)
end

-- ------------------------------------------------------------------------------------------------
-- Tile Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:resetTileProperties`. 
-- @override resetTileProperties
function CallAction:resetTileProperties(input)
  self:resetSelectableTiles(input)
end
--- Overrides `BattleAction:resetTileColors`. 
-- @override resetTileColors
function CallAction:resetTileColors(input)
  for tile in self.field:gridIterator() do
    if tile.gui.selectable then
      tile.gui:setColor(self.colorName)
    else
      tile.gui:setColor('')
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Selectable Tiles
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:isSelectable`. 
-- @override isSelectable
function CallAction:isSelectable(input, tile)
  return tile.party == (input.party or input.user.party) and not tile:collides(0, 0) 
    and not self.field:collidesTerrain(tile:coordinates())
end

-- ------------------------------------------------------------------------------------------------
-- Troop
-- ------------------------------------------------------------------------------------------------

--- Adds a character to the field that represents the member with the given key.
-- @tparam string key Member's key.
-- @tparam ObjectTile tile The tile the character will be put in.
-- @tparam boolean fade Flag to show character fading in.
-- @treturn Character The newly created character for the member.
function CallAction:callMember(key, tile, fade)
  assert(key, 'No character was chosen!')
  assert(tile, 'No tile was chosen!')
  local x = tile.x - self.troop.x
  local y = tile.y - self.troop.y
  self.troop:moveMember(key, 0, x, y)
  local battler = self.troop.battlers[key]
  if self.resetBattler then
    battler:resetState()
  end
  local dir = self.troop:getCharacterDirection()
  local character = TroopManager:createCharacter(tile, dir, battler, self.troop.party)
  if fade then
    character:colorizeTo(nil, nil, nil, 0)
    character:colorizeTo(nil, nil, nil, 1, self.animSpeed, true)
  end
  TroopManager:createBattler(character)
  return character
end
--- Removes a member character.
-- @tparam Character char The characters representing the member to be removed.
-- @treturn table Removed member's data.
function CallAction:removeMember(char)
  local member = self.troop:moveMember(char.key, 1)
  TroopManager:deletechar(character)
  return member
end

return CallAction
