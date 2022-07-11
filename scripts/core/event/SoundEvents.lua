
--[[===============================================================================================

Sound Utilities
---------------------------------------------------------------------------------------------------
Functions that are loaded from the EventSheet.

=================================================================================================]]

local EventSheet = {}

---------------------------------------------------------------------------------------------------
-- Sound
---------------------------------------------------------------------------------------------------

-- General parameters:
-- @param(args.name : string) The path to the sound from audio/bgm (BGMs) or audio/sfx (SFX).
-- @param(args.volume : number) Volume in percentage.
-- @param(args.pitch : number) Pitch in percentage.
-- @param(args.time : number) The duration of the BGM fading transition.
-- @param(args.wait : boolean) Wait for the BGM fading transition or until SFX finishes.

-- Changes the current BGM.
function EventSheet:playBGM(sheet, args)
  AudioManager:playBGM(args, args.time, args.wait)
end
-- Pauses current BGM.
function EventSheet:pauseBGM(sheet, args)
  AudioManager:pauseBGM(args, args.time, args.wait)
end
-- Resumes current BGM.
function EventSheet:resumeBGM(sheet, args)
  AudioManager:resumeBGM(args, args.time, args.wait)
end
-- Play a sound effect.
function EventSheet:playSFX(sheet, args)
  AudioManager:playSFX(args)
end

return EventSheet
