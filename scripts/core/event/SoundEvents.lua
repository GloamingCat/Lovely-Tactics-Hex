
-- ================================================================================================

--- Audio-related functions that are loaded from the EventSheet.
---------------------------------------------------------------------------------------------------
-- @module SoundEvents

-- ================================================================================================

local SoundEvents = {}

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Common arguments for sound commands.
-- @table SoundArguments
-- @tfield[opt=''] string name The path to the sound from `audio/bgm/` (BGMs) or `audio/sfx/` (SFX).
-- @tfield[opt=1] number volume Volume multiplier, in percentage.
-- @tfield[opt=1] number pitch Pitch multiplier, in percentage.
-- @tfield[opt=0] number time The duration of the BGM fading transition in frames.
-- @tfield[opt] boolean wait Wait for the BGM fading transition or until SFX finishes.

-- ------------------------------------------------------------------------------------------------
-- Sound
-- ------------------------------------------------------------------------------------------------

--- Changes the current BGM.
-- @coroutine
-- @tparam SoundArguments args Argument table.
function SoundEvents:playBGM(args)
  AudioManager:playBGM(args, args.time, args.wait)
end
--- Pauses current BGM.
-- @coroutine
-- @tparam SoundArguments args Argument table.
function SoundEvents:pauseBGM(args)
  AudioManager:pauseBGM(args.time, args.wait)
end
--- Resumes current BGM.
-- @coroutine
-- @tparam SoundArguments args Argument table.
function SoundEvents:resumeBGM(args)
  AudioManager:resumeBGM(args.time, args.wait)
end
--- Play a sound effect.
-- @tparam SoundArguments args Argument table.
function SoundEvents:playSFX(args)
  AudioManager:playSFX(args)
end
--- Play the BGM of current field.
-- If the `name` field is set, it will set the field's BGM to this new sound.
-- @coroutine
-- @tparam SoundArguments args Argument table.
function SoundEvents:playFieldBGM(args)
  if args.name then
    FieldManager.currentField.bgm.name = args.name
  end
  FieldManager.currentField:playBGM(args.time, args.wait)
end

return SoundEvents
