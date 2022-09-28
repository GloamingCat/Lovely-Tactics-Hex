
--[[===============================================================================================

Music
---------------------------------------------------------------------------------------------------
A type of sounds that loops and may have a non-looping intro.

=================================================================================================]]

-- Imports
local Sound = require('core/audio/Sound')

local Music = class(Sound)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(name : string) Name of the file from the audio folder.
-- @param(volume : number) Initial volume (from 0 to 100).
-- @param(pitch : number) Initial pitch (from 0 to 100).
-- @param(intro : Source) Intro source (optional).
-- @param(loop : Source) Loop source (optional).
function Music:init(name, volume, pitch, intro, loop)
  self.name = name
  self.intro, self.loop = ResourceManager:loadBGM(name, intro, loop)
  self:initSource(self.intro or self.loop, volume, pitch)
end

---------------------------------------------------------------------------------------------------
-- Looping
---------------------------------------------------------------------------------------------------

-- Checks looping.
function Music:update()
  if self.source == self.intro and self:isFinished() then
    self.intro:stop()
    self.source = self.loop
    self:refreshPitch()
    self:refreshVolume()
    self.source:play()
  end
end
-- Overrides Sound:getDuration.
function Music:getDuration(unit)
  return (self.intro and self.intro:getDuration(unit) or 0) + self.loop:getDuration(unit)
end

---------------------------------------------------------------------------------------------------
-- Playing
---------------------------------------------------------------------------------------------------

-- Overrides Sound:stop.
function Music:stop()
  if self.intro then
    self.intro:stop()
    self.intro:seek(0)
  end
  self.loop:stop()
  self.loop:seek(0)
  self.source = self.intro or self.loop
end

---------------------------------------------------------------------------------------------------
-- Volume & Pitch
---------------------------------------------------------------------------------------------------

-- Overrides Sound:refreshVolume.
function Music:refreshVolume()
  self.source:setVolume((self.volume / 100) * (AudioManager.volumeBGM / 100) * AudioManager.fading)
end
-- Overrides Sound:refreshPitch.
function Music:refreshPitch()
  self.source:setPitch((self.pitch / 100) * (AudioManager.pitchBGM / 100) * GameManager.speed)
end

return Music
