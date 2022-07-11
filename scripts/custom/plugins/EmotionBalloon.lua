
--[[===============================================================================================

EmotionBalloon
---------------------------------------------------------------------------------------------------
The balloon animation to show a battler's emotion. The "balloon" and "emotions" animations must be
set in the project's config.

=================================================================================================]]

-- Imports
local CharacterBase = require('core/objects/CharacterBase')
local EventSheet = require('core/fiber/EventSheet')

-- Custom
local keyToRow = {}
keyToRow['!'] = 0 -- Surprised
keyToRow['?'] = 1 -- Confused
keyToRow['...'] = 2 -- Silent
keyToRow['@'] = 3 -- Angry
keyToRow['<3'] = 4 -- Love

---------------------------------------------------------------------------------------------------
-- CharacterBase
---------------------------------------------------------------------------------------------------

-- Override. Updates balloon position when character moves.
local CharacterBase_setXYZ = CharacterBase.setXYZ
function CharacterBase:setXYZ(x, y, z)
  CharacterBase_setXYZ(self, x, y, z)
  if self.balloon then
    self.balloon:updatePosition(self)
  end
end
-- Override. Updates balloon animation.
local CharacterBase_update = CharacterBase.update
function CharacterBase:update()
  CharacterBase_update(self)
  if not self.paused and self.balloon then
    self.balloon:update()
  end
end
-- Override. Destroys balloon with characters is destroyed.
local CharacterBase_destroy = CharacterBase.destroy
function CharacterBase:destroy(...)
  CharacterBase_destroy(self, ...)
  if self.balloon then
    self.balloon:destroy()
  end
end

---------------------------------------------------------------------------------------------------
-- EventSheet
---------------------------------------------------------------------------------------------------

-- Show an emotion animation inside character's balloon.
-- @param(args.emotion : number | string) Emotion's row or key (from keyToRow custom table).
-- @param(args.loop : bool) If true, do not destroy balloon, and instead loops animation.
function EventSheet:showCharBalloon(args)
  local character = self:findCharacter(args.key)
  if not character.balloon then
    local balloonID = Config.animations.balloon
    assert(balloonID, "Animation 'balloon' not set.")
    character.balloon = ResourceManager:loadAnimation(balloonID, FieldManager.renderer)
    character.balloon.sprite:setTransformation(character.balloon.data.transform)
  end
  assert(character.balloon.setIcon, "Character's balloon is not a Balloon animation: "
    .. tostring(character.balloon))
  local emotionsID = Config.animations.emotions
  assert(emotionsID, "Animation 'emotions' not set.")
  local iconAnim = ResourceManager:loadAnimation(emotionsID, FieldManager.renderer)
  if type(args.emotion) == 'number' then
    iconAnim:setRow(args.emotion)
  else
    assert(keyToRow[args.emotion], "Emotion '" .. tostring(args.emotion) .. "' does not exist!")
    iconAnim:setRow(keyToRow[args.emotion])
  end
  iconAnim:hide()
  character.balloon:setIcon(iconAnim)
  character:setPosition(character.position)
  if not args.loop then
    local totalDuration = character.balloon.duration
    self:invoke(totalDuration, character.balloon.finish, character.balloon)
  end
  if not args.silent and Config.sounds[args.emotion] then
    AudioManager:playSFX(Config.sounds[args.emotion])
  end
end
