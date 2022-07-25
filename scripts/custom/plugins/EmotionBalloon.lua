
--[[===============================================================================================

EmotionBalloon
---------------------------------------------------------------------------------------------------
The balloon animation to show a battler's emotion. The "balloon" and "emotions" animations must be
set in the project's config.

-- Requires: 
ChildAnimations

=================================================================================================]]

-- Imports
local CharacterBase = require('core/objects/CharacterBase')
local CharacterEvents = require('core/event/CharacterEvents')

-- Custom
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

---------------------------------------------------------------------------------------------------
-- CharacterBase
---------------------------------------------------------------------------------------------------

-- Override. Updates balloon position when character moves.
local CharacterBase_setXYZ = CharacterBase.setXYZ
function CharacterBase:setXYZ(x, y, z)
  CharacterBase_setXYZ(self, x, y, z)
  if self.balloon then
    local p = self.position
    local h = self:getPixelHeight() + (self.jumpHeight or 0)
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
function CharacterBase:createBalloon()
  if not self.balloon then
    local balloonID = Config.animations.balloon
    assert(balloonID, "Animation 'balloon' not set.")
    self.balloon = ResourceManager:loadAnimation(balloonID, FieldManager.renderer)
    self.balloon.sprite:setTransformation(self.balloon.data.transform)
  end
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
  local emotionsID = Config.animations.emotions
  assert(emotionsID, "Animation 'emotions' not set.")
  local iconAnim = ResourceManager:loadAnimation(emotionsID, FieldManager.renderer)
  if type(args.emotion) == 'number' then
    iconAnim:setRow(args.emotion)
  else
    assert(keyToRow[args.emotion], "Emotion '" .. tostring(args.emotion) .. "' does not exist!")
    iconAnim:setRow(keyToRow[args.emotion])
  end
  character.balloon:addChild(iconAnim)
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
  local icon = args.icon
  if type(icon) == 'string' then
    icon = Config.icons[icon]
  end
  local iconSprite = ResourceManager:loadIcon(icon)
  local iconAnim = Animation(iconSprite, Database.animations[icon.id])
  local patternData = {
    introPattern = tostring(iconAnim.colCount - 1) .. ' ' .. icon.col,
    introDuration = iconAnim.data.introDuration }
  iconAnim:initPattern(patternData)
  iconAnim:setRow(icon.row)
  character.balloon:addChild(iconAnim)
  character:setPosition(character.position)
end
