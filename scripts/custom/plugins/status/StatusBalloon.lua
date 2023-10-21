
-- ================================================================================================

--- The balloon animation to show a battler's status list. The "balloon" animation must be set in 
-- the project's config.
-- 
-- Requires: 
--  * EmotionBallon
---------------------------------------------------------------------------------------------------
-- @plugin StatusBalloon

-- ================================================================================================

-- Imports
local BattleCursor = require('core/battle/BattleCursor')
local CharacterBase = require('core/objects/CharacterBase')
local StatusList = require('core/battle/battler/StatusList')

-- Rewrites
local StatusList_updateGraphics = StatusList.updateGraphics
local CharacterBase_update = CharacterBase.update
local BattleCursor_setTile = BattleCursor.setTile
local BattleCursor_setCharacter = BattleCursor.setCharacter

-- ------------------------------------------------------------------------------------------------
-- StatusList
-- ------------------------------------------------------------------------------------------------

--- Rewrites `StatusList:updateGraphics`.
-- @rewrite
function StatusList:updateGraphics(character)
  StatusList_updateGraphics(self, character)
  character.statusIcons = self:getIcons()
  character.statusIndex = 0
end

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Rewrites `CharacterBase:update`.
-- @rewrite
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

--- Rewrites `BattleCursor:setTile`.
-- @rewrite
function BattleCursor:setTile(tile)
  BattleCursor_setTile(self, tile)
  for char in tile.characterList:iterator() do
    if char.balloon then
      self:addBalloonHeight(char.balloon)
      break
    end
  end
end
--- Rewrites `BattleCursor:setCharacter`.
-- @rewrite
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
