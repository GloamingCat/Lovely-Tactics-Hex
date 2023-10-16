
--[[===============================================================================================

@script StatusBalloon
---------------------------------------------------------------------------------------------------
-- The balloon animation to show a battler's status list. The "balloon" animation must be set in 
-- the project's config.
-- 
-- Requires: 
--  * EmotionBallon

=================================================================================================]]

-- Imports
local BattleCursor = require('core/battle/BattleCursor')
local CharacterBase = require('core/objects/CharacterBase')
local StatusList = require('core/battle/battler/StatusList')

-- ------------------------------------------------------------------------------------------------
-- StatusList
-- ------------------------------------------------------------------------------------------------

--- Override. Refreshes icon list.
local StatusList_updateGraphics = StatusList.updateGraphics
function StatusList:updateGraphics(character)
  StatusList_updateGraphics(self, character)
  character.statusIcons = self:getIcons()
  character.statusIndex = 0
end

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Override. Considers state 4, when the character has no status.
local CharacterBase_update = CharacterBase.update
function CharacterBase:update(dt)
  CharacterBase_update(self, dt)
  if self.statusIcons and #self.statusIcons > 0 then 
    if not self.balloon then
      self:nextStatusIcon()
    end
  end
end
--- Sets the icon to the next icon in the list.
function CharacterBase:nextStatusIcon()
  self.statusIndex = math.mod1(self.statusIndex + 1, #self.statusIcons)
  self:createBalloon()
  local icon = self.statusIcons[self.statusIndex]
  self.balloon:addChild(ResourceManager:loadBalloonIconAnimation(icon, FieldManager.renderer))
  self:setPosition(self.position)
end

-- ------------------------------------------------------------------------------------------------
-- BattleCursor
-- ------------------------------------------------------------------------------------------------

--- Override. Adds balloon height if there are characters with a balloon.
local BattleCursor_setTile = BattleCursor.setTile
function BattleCursor:setTile(tile)
  BattleCursor_setTile(self, tile)
  for char in tile.characterList:iterator() do
    if char.balloon then
      self:addBalloonHeight(char.balloon)
      break
    end
  end
end
--- Override. Adds balloon height if character has a balloon.
local BattleCursor_setCharacter = BattleCursor.setCharacter
function BattleCursor:setCharacter(char)
  BattleCursor_setCharacter(self, char)
  if char.balloon then
    self:addBalloonHeight(char.balloon)
  end
end
--- Translates cursor to above the balloon.
-- @tparam Balloon balloon Character's balloon.
function BattleCursor:addBalloonHeight(balloon)
  local sprite = self.anim.sprite
  local _, by = balloon.sprite:totalBounds()
  sprite:setXYZ(nil, math.min(sprite.position.y, by + 8))
end
