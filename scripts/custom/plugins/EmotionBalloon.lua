
-- ================================================================================================

--- The balloon animation to show a battler's emotion. The "balloon" and "emotions" animations must 
-- be set in the project's config.
-- 
-- Requires: 
--  * ChildAnimations
--
-- Plugin parameters:
--  * Use <balloonY> to shift the balloon sprite in pixels.
--  * Use <emotions> to set a different list of emotions. It should be a list of strings, with each
--  string being the emotion's code.
--  * Use <rows> to set custons rows for each emotion. The rows should be in the same order as the
--  emotions listed in <emotions>.
---------------------------------------------------------------------------------------------------
-- @plugin EmotionBalloon

-- ================================================================================================

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
  for i, e in ipairs(args.emotions) do
    keyToRow[e] = args.rows and args.rows[i] or i
  end
end
local balloonY = args.balloonY or 0

-- ------------------------------------------------------------------------------------------------
-- ResourceManager
-- ------------------------------------------------------------------------------------------------

--- Creates an animation given the emotion identifier.
-- @tparam number|string emotion Emotion's key or row number.
-- @tparam Renderer renderer
-- @treturn Animation
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
--- Creates an icon animation for balloons.
-- @tparam table|string icon Icon data or name (from config).
-- @tparam Renderer renderer
-- @treturn Animation
function ResourceManager:loadBalloonIconAnimation(icon, renderer)
  if type(icon) == 'string' then
    icon = Config.icons[icon]
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

-- ------------------------------------------------------------------------------------------------
-- CharacterBase
-- ------------------------------------------------------------------------------------------------

--- Overrides `CharacterBase:setXYZ`. Updates balloon position when character moves.
-- @override setXYZ
local CharacterBase_setXYZ = CharacterBase.setXYZ
function CharacterBase:setXYZ(x, y, z)
  CharacterBase_setXYZ(self, x, y, z)
  if self.balloon then
    local p = self.position
    local h = self:getPixelHeight() + (self.jumpHeight or 0) + balloonY
    self.balloon:setXYZ(p.x, p.y - h, p.z)
    self.balloon.children[1]:setXYZ(p.x, p.y - h, p.z - 1)
    --self.iconAnim:setXYZ(p.x, p.y - h - self.height / 2, p.z - 1)
  end
end
--- Rewrites `CharacterBase:update`.
-- @override CharacterBase_update
local CharacterBase_update = CharacterBase.update
function CharacterBase:update(dt)
  CharacterBase_update(self, dt)
  if not self.paused and self.balloon then
    self.balloon:update(dt)
    if self.balloon.paused then -- Balloon animation ended
      self.balloon:destroy()
      self.balloon = nil
    end
  end
end
--- Rewrites `CharacterBase:destroy`.
-- @override CharacterBase_destroy
local CharacterBase_destroy = CharacterBase.destroy
function CharacterBase:destroy(...)
  CharacterBase_destroy(self, ...)
  if self.balloon then
    self.balloon:destroy()
    self.balloon = nil
  end
end
--- Creates a balloon animation, if there is none.
function CharacterBase:createBalloon()
  if self.balloon then
    return
  end
  -- Create balloon animation.
  local balloonID = Config.animations.balloon
  assert(balloonID, "Animation 'balloon' not set.")
  self.balloon = ResourceManager:loadAnimation(balloonID, FieldManager.renderer)
  self.balloon.sprite:setTransformation(self.balloon.data.transform)
end

-- ------------------------------------------------------------------------------------------------
-- CharacterEvents
-- ------------------------------------------------------------------------------------------------

--- Show an emotion animation inside character's balloon.
-- @tparam table args
--  args.emotion (number|string): Emotion's row or key (from keyToRow custom table).
--  args.loop (boolean): If true, do not destroy balloon, and instead loops animation.
function CharacterEvents:showEmotionBalloon(args)
  local character = self:findCharacter(args.key)
  character:createBalloon()
  character.balloon:addChild(_G.ResourceManager:loadEmotionAnimation(args.emotion, FieldManager.renderer))
  character:setPosition(character.position)
  if not args.silent and Config.sounds[args.emotion] then
    AudioManager:playSFX(Config.sounds[args.emotion])
  end
end
--- Show an emotion animation inside character's balloon.
-- @tparam table args
--  args.icon (table|string) Icon data or icon name (from config data).
--  args.loop (boolean) If true, do not destroy balloon, and instead loops animation.
function CharacterEvents:showIconBalloon(args)
  local character = self:findCharacter(args.key)
  character:createBalloon()
  character.balloon:addChild(_G.ResourceManager:loadBalloonIconAnimation(args.icon, FieldManager.renderer))
  character:setPosition(character.position)
end
