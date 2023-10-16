
--[[===============================================================================================

@module SoundEvents
---------------------------------------------------------------------------------------------------
Audio-related functions that are loaded from the EventSheet.

=================================================================================================]]

local SoundEvents = {}

-- ------------------------------------------------------------------------------------------------
-- Sound
-- ------------------------------------------------------------------------------------------------

-- General parameters:
-- @tparam args.name string The path to the sound from audio/bgm (BGMs) or audio/sfx (SFX).
-- @tparam args.volume number Volume in percentage.
-- @tparam args.pitch number Pitch in percentage.
-- @tparam args.time number The duration of the BGM fading transition.
-- @tparam args.wait boolean Wait for the BGM fading transition or until SFX finishes.

--- Changes the current BGM.
function SoundEvents:playBGM(sheet, args)
  AudioManager:playBGM(args, args.time, args.wait)
end
--- Pauses current BGM.
function SoundEvents:pauseBGM(sheet, args)
  AudioManager:pauseBGM(args, args.time, args.wait)
end
--- Resumes current BGM.
function SoundEvents:resumeBGM(sheet, args)
  AudioManager:resumeBGM(args, args.time, args.wait)
end
--- Play a sound effect.
function SoundEvents:playSFX(sheet, args)
  AudioManager:playSFX(args)
end

return SoundEvents
