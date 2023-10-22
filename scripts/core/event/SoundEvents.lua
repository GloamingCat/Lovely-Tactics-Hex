
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
-- @tfield string name The path to the sound from `audio/bgm/` (BGMs) or `audio/sfx/` (SFX).
-- @tfield number volume Volume multiplier (0-1).
-- @tfield number pitch Pitch multiplier (0-1).
-- @tfield number time The duration of the BGM fading transition in frames.
-- @tfield boolean wait Wait for the BGM fading transition or until SFX finishes.

-- ------------------------------------------------------------------------------------------------
-- Sound
-- ------------------------------------------------------------------------------------------------

--- Changes the current BGM.
-- @tparam SoundArguments args
function SoundEvents:playBGM(args)
  AudioManager:playBGM(args, args.time, args.wait)
end
--- Pauses current BGM.
-- @tparam SoundArguments args
function SoundEvents:pauseBGM(args)
  AudioManager:pauseBGM(args, args.time, args.wait)
end
--- Resumes current BGM.
-- @tparam SoundArguments args
function SoundEvents:resumeBGM(args)
  AudioManager:resumeBGM(args, args.time, args.wait)
end
--- Play a sound effect.
-- @tparam SoundArguments args
function SoundEvents:playSFX(args)
  AudioManager:playSFX(args)
end

return SoundEvents
