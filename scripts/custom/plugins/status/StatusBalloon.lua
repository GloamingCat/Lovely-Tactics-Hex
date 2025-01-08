
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
local AnimatedInteractable = require('core/objects/AnimatedInteractable')
local StatusList = require('core/battle/battler/StatusList')

-- Rewrites
local StatusList_updateGraphics = StatusList.updateGraphics
local AnimatedInteractable_update = AnimatedInteractable.update
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

--- Rewrites `AnimatedInteractable:update`.
-- @rewrite
function AnimatedInteractable:update(dt)
  AnimatedInteractable_update(self, dt)
  if self.statusIcons and #self.statusIcons > 0 then 
    if not self.balloon then
      self:nextStatusIcon()
    end
  end
end
--- Sets the icon to the next icon in the list.
function AnimatedInteractable:nextStatusIcon()
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
  local _, y1, _, y2 = balloon.sprite:getBoundingBox()
  sprite:setXYZ(nil, math.min(sprite.position.y, y2 - y1 + 8))
end
