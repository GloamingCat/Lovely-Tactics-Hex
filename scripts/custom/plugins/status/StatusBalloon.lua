
--[[===============================================================================================

StatusBalloon
---------------------------------------------------------------------------------------------------
The balloon animation to show a battler's status. The "balloon" animation must be set in the 
project's config.

-- Requires: 
EmotionBallon

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')
local Balloon = require('custom/animation/Balloon')
local BattleCursor = require('core/battle/BattleCursor')
local List = require('core/datastruct/List')
local Sprite = require('core/graphics/Sprite')
local StatusList = require('core/battle/battler/StatusList')
local TroopManager = require('core/battle/TroopManager')

-- Alias
local Image = love.graphics.newImage

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Override. Initializes state and icon animation.
local Balloon_init = Balloon.init
function Balloon:init(...)
  Balloon_init(self, ...)
  self.state = 4
  self.statusIndex = 0
  self.status = {}
  self.sprite:setCenterOffset()
  self:hide()
end
-- Creates the icon animation.
function Balloon:initIcon()
  local sprite = Sprite(FieldManager.renderer)
  local anim = Animation(sprite)
  anim.duration = 30
  self:setIcon(anim)
end
-- Override. Considers state 4, when the character has no status.
local Balloon_update = Balloon.update
function Balloon:update()
  if self.state ~= 4 then
    Balloon_update(self)
  end
end
-- Override. Checks for status and changes the icon.
local Balloon_onEnd = Balloon.onEnd
function Balloon:onEnd()
  Balloon_onEnd(self)
  if self.state == 1 and #self.status > 0 then -- Show next icon
    self:nextIcon()
  end
end
-- Sets the icon to the next icon in the list.
function Balloon:nextIcon()
  self.statusIndex = math.mod1(self.statusIndex + 1, #self.status)
  local icon = self.status[self.statusIndex]
  local data = Database.animations[icon.id]
  local quad, texture = ResourceManager:loadQuad(data.quad, nil, data.cols, data.rows, icon.col, icon.row)
  self.iconAnim.sprite:setTexture(texture)
  self.iconAnim.sprite:setQuad(quad)
  self.iconAnim.sprite:setCenterOffset()
  local x, y, w, h = quad:getViewport()
  self.iconAnim.quadWidth = w
  self.iconAnim.quadHeight = h
end
-- Sets the list of status icons. If empty, the balloon is hidden.
-- @param(icons : table) Array of icon data.
function Balloon:setIcons(icons)
  self.status = icons
  self:reset()
  if #icons > 0 then
    if self.state == 4 then
      self:nextIcon()
      self:show()
      self.state = 0
    end
  else
    self.state = 4
    self.iconAnim:reset()
    self.iconAnim:hide()
    self:hide()
  end
end
-- Override. Sets correct state when a single icon is set (for emotion balloons).
local Balloon_setIcon = Balloon.setIcon
function Balloon:setIcon(anim)
  Balloon_setIcon(self, anim)
  if anim then
    self.state = 0
    self:show()
  else
    self.state = 4
    self:hide()
  end
end

---------------------------------------------------------------------------------------------------
-- StatusList
---------------------------------------------------------------------------------------------------

-- Override. Refreshes icon list.
local StatusList_updateGraphics = StatusList.updateGraphics
function StatusList:updateGraphics(character)
  StatusList_updateGraphics(self, character)
  if character.balloon then
    local icons = self:getIcons()
    character.balloon:setIcons(icons)
  end
end

---------------------------------------------------------------------------------------------------
-- TroopManager
---------------------------------------------------------------------------------------------------

-- Override. Creates a balloon for each battle character.
local TroopManager_createBattler = TroopManager.createBattler
function TroopManager:createBattler(character)
  if character.party >= 0 then
    if not character.balloon then
      local balloonID = Config.animations.balloon
      character.balloon = ResourceManager:loadAnimation(balloonID, FieldManager.renderer)
      character.balloon.sprite:setTransformation(character.balloon.data.transform)
    end
    if not character.balloon.iconAnim then
        character.balloon:initIcon()
    end
  end
  TroopManager_createBattler(self, character)
  if character.battler then
    local icons = character.battler.statusList:getIcons()
    assert(character.balloon.setIcons, "Character's balloon is not a Balloon animation: "
      .. tostring(character.balloon))
    character.balloon:setIcons(icons)
    character:setPosition(character.position)
  end
end

---------------------------------------------------------------------------------------------------
-- BattleCursor
---------------------------------------------------------------------------------------------------

-- Override. Adds balloon height if there are characters with a balloon.
local BattleCursor_setTile = BattleCursor.setTile
function BattleCursor:setTile(tile)
  BattleCursor_setTile(self, tile)
  for char in tile.characterList:iterator() do
    if char.balloon and char.balloon.state ~= 4 then
      self:addBalloonHeight(char.balloon)
      break
    end
  end
end
-- Override. Adds balloon height if character has a balloon.
local BattleCursor_setCharacter = BattleCursor.setCharacter
function BattleCursor:setCharacter(char)
  BattleCursor_setCharacter(self, char)
  if char.balloon and char.balloon.state ~= 4 then
    self:addBalloonHeight(char.balloon)
  end
end
-- Translates cursor to above the balloon.
-- @param(balloon : Balloon) Character's balloon.
function BattleCursor:addBalloonHeight(balloon)
  local sprite = self.anim.sprite
  local _, by = balloon.sprite:totalBounds()
  sprite:setXYZ(nil, math.min(sprite.position.y, by + 8))
end
