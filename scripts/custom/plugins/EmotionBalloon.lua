
-- ================================================================================================

--- The balloon animation to show a battler's emotion. The `"balloon"` and `"emotions"` animations 
-- must be set in the project's config.
-- 
-- Requires: `ChildAnimations`
---------------------------------------------------------------------------------------------------
-- @plugin EmotionBalloon

--- Plugin parameters.
-- @tags Plugin
-- @tfield number ballonY Vertical shift in pixels applied to the balloon sprite (optional).
-- @tfield table emotions Array of strings to set a different list of emotions, with each string 
--  being the emotion's code (optional, uses the set `["!", "?", "...", "@", <3"]` by default).
-- @tfield table rows Array of numbers to set custom rows for each emotion. The rows should be in the
--  same order as the emotions listed in `emotions` (optional, uses `0` to `#emotions - 1` by default).

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')
local AnimatedInteractable = require('core/objects/AnimatedInteractable')
local CharacterEvents = require('core/event/CharacterEvents')
local ResourceManager = require('core/base/ResourceManager')

-- Rewrites
local AnimatedInteractable_setXYZ = AnimatedInteractable.setXYZ
local AnimatedInteractable_update = AnimatedInteractable.update
local AnimatedInteractable_destroy = AnimatedInteractable.destroy

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
-- AnimatedInteractable
-- ------------------------------------------------------------------------------------------------

--- Rewrites `AnimatedInteractable:setXYZ`. Updates balloon position when character moves.
-- @rewrite
function AnimatedInteractable:setXYZ(x, y, z)
  AnimatedInteractable_setXYZ(self, x, y, z)
  if self.balloon then
    local p = self.position
    local h = self:getPixelHeight() + (self.jumpHeight or 0) + balloonY
    self.balloon:setXYZ(p.x, p.y - h, p.z)
    self.balloon.children[1]:setXYZ(p.x, p.y - h, p.z - 1)
    --self.iconAnim:setXYZ(p.x, p.y - h - self.height / 2, p.z - 1)
  end
end
--- Rewrites `AnimatedInteractable:update`. Updates balloon animation.
-- @rewrite
function AnimatedInteractable:update(dt)
  AnimatedInteractable_update(self, dt)
  if not self.paused and self.balloon then
    self.balloon:update(dt)
    if self.balloon.paused then -- Balloon animation ended
      self.balloon:destroy()
      self.balloon = nil
    end
  end
end
--- Rewrites `AnimatedInteractable:destroy`. Destroys balloon object.
-- @rewrite
function AnimatedInteractable:destroy(...)
  AnimatedInteractable_destroy(self, ...)
  if self.balloon then
    self.balloon:destroy()
    self.balloon = nil
  end
end
--- Creates a balloon animation, if there is none.
function AnimatedInteractable:createBalloon()
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
