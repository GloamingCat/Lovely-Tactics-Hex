
--[[===============================================================================================

EmotionBalloon
---------------------------------------------------------------------------------------------------
The balloon animation to show a battler's emotion. The "balloon" and "emotions" animations must be
set in the project's config.

-- Requires: 
ChildAnimations

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')
local CharacterBase = require('core/objects/CharacterBase')
local CharacterEvents = require('core/event/CharacterEvents')
local ResourceManager = require('core/base/ResourceManager')

-- Parameters
local keyToRow = {}
keyToRow['!'] = 0 -- Surprised
keyToRow['?'] = 1 -- Confused
keyToRow['...'] = 2 -- Silent
keyToRow['@'] = 3 -- Angry
keyToRow['<3'] = 4 -- Love
if args.emotions then
  for i = 1, #args.emotions do
    local e = args.emotions[i]:split()
    keyToRow[e[1]] = tonumber(e[2])
  end
end
local balloonY = tonumber(args.balloonY) or 0

---------------------------------------------------------------------------------------------------
-- ResourceManager
---------------------------------------------------------------------------------------------------

-- Creates an animation given the emotion identifier.
-- @param(emotion : number | string) Emotion's key or row number.
-- @param(renderer : Renderer)
-- @ret(Animation)
function ResourceManager:loadEmotionAnimation(emotion, renderer)
  -- Emotion animation
  local emotionsID = Config.animations.emotions
  assert(emotionsID, "Animation 'emotions' not set.")
  if type(emotion) == 'string' then
    assert(keyToRow[emotion], "Emotion '" .. tostring(emotion) .. "' does not exist!")
    emotion = keyToRow[emotion]
  end
  local anim = self:loadAnimation(emotionsID, renderer)
  anim:setRow(emotion)
  return anim
end
-- Creates an icon animation for balloons.
-- @param(emotion : table | string) Icon data or name (from config).
-- @param(renderer : Renderer)
-- @ret(Animation)
function ResourceManager:loadBalloonIconAnimation(icon, renderer)
  if type(icon) == 'string' then
    icon = Config.icons[icon]
    print(icon.id, icon.col, icon.row)
  end
  local sprite = ResourceManager:loadIcon({id = icon.id, row = 0, col = 0}, renderer)
  local anim = Animation(sprite, Database.animations[icon.id])
  local emptyCol = tostring(anim.colCount - 1)
  local patternData = {
    introPattern = emptyCol .. ' ' .. icon.col .. ' ' .. emptyCol,
    introDuration = anim.data.introDuration }
  anim:initPattern(patternData)
  anim:setRow(icon.row)
  anim:reset()
  return anim
end

---------------------------------------------------------------------------------------------------
-- CharacterBase
---------------------------------------------------------------------------------------------------

-- Override. Updates balloon position when character moves.
local CharacterBase_setXYZ = CharacterBase.setXYZ
function CharacterBase:setXYZ(x, y, z)
  CharacterBase_setXYZ(self, x, y, z)
  if self.balloon then
    local p = self.position
    local h = self:getPixelHeight() + (self.jumpHeight or 0) + balloonY
    self.balloon.sprite:setXYZ(p.x, p.y - h, p.z)
    self.balloon.children[1].sprite:setXYZ(p.x, p.y - h, p.z - 1)
    --self.iconAnim.sprite:setXYZ(p.x, p.y - h - self.height / 2, p.z - 1)
  end
end
-- Override. Updates balloon animation.
local CharacterBase_update = CharacterBase.update
function CharacterBase:update()
  CharacterBase_update(self)
  if not self.paused and self.balloon then
    self.balloon:update()
    if self.balloon.paused then -- Balloon animation ended
      self.balloon:destroy()
      self.balloon = nil
    end
  end
end
-- Override. Destroys balloon with characters is destroyed.
local CharacterBase_destroy = CharacterBase.destroy
function CharacterBase:destroy(...)
  CharacterBase_destroy(self, ...)
  if self.balloon then
    self.balloon:destroy()
    self.balloon = nil
  end
end
-- Creates a balloon animation, if there is none.
-- @param(icon : table | string | number) Row number or emotion name to show emotion animation,
--  or icon or icon name to show icon animation.
function CharacterBase:createBalloon(anim)
  if self.balloon then
    return
  end
  -- Create balloon animation.
  local balloonID = Config.animations.balloon
  assert(balloonID, "Animation 'balloon' not set.")
  self.balloon = ResourceManager:loadAnimation(balloonID, FieldManager.renderer)
  self.balloon.sprite:setTransformation(self.balloon.data.transform)
end

---------------------------------------------------------------------------------------------------
-- CharacterEvents
---------------------------------------------------------------------------------------------------

-- Show an emotion animation inside character's balloon.
-- @param(args.emotion : number | string) Emotion's row or key (from keyToRow custom table).
-- @param(args.loop : bool) If true, do not destroy balloon, and instead loops animation.
function CharacterEvents:showEmotionBalloon(args)
  local character = self:findCharacter(args.key)
  character:createBalloon()
  character.balloon:addChild(_G.ResourceManager:loadEmotionAnimation(args.emotion, FieldManager.renderer))
  character:setPosition(character.position)
  if not args.silent and Config.sounds[args.emotion] then
    AudioManager:playSFX(Config.sounds[args.emotion])
  end
end
-- Show an emotion animation inside character's balloon.
-- @param(args.icon : table | string) Icon data or icon name (from config data).
-- @param(args.loop : bool) If true, do not destroy balloon, and instead loops animation.
function CharacterEvents:showIconBalloon(args)
  local character = self:findCharacter(args.key)
  character:createBalloon()
  character.balloon:addChild(_G.ResourceManager:loadBalloonIconAnimation(args.icon, FieldManager.renderer))
  character:setPosition(character.position)
end
