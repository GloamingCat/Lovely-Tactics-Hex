
--[[===============================================================================================

Sound
---------------------------------------------------------------------------------------------------
A class representing a sound.

=================================================================================================]]

local Sound = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(name : string) Name of the file from the audio folder.
-- @param(volume : number) Initial volume (from 0 to 100).
-- @param(pitch : number) Initial pitch (from 0 to 100).
function Sound:init(name, volume, pitch)
  self:initSource(ResourceManager:loadSFX(name), volume, pitch)
end
-- Initializes source.
-- @param(source : Source) The audio source.
-- @param(volume : number) Initial volume (from 0 to 100).
-- @param(pitch : number) Initial pitch (from 0 to 100).
function Sound:initSource(source, volume, pitch)
  self.volume = volume or 100
  self.pitch = pitch or 100
  self.source = source
  self:refreshVolume()
  self:refreshPitch()
  self.paused = true
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Tells if the sound already ended.
-- @ret(boolean)
function Sound:isFinished()
  return not (self.source:isPlaying() or self.paused)
end
-- @param(unit : string) "seconds" or "samples" (first by default)
-- @ret(number) the duration in the given unit
function Sound:getDuration()
  return self.source:getDuration()
end

---------------------------------------------------------------------------------------------------
-- Playing
---------------------------------------------------------------------------------------------------

-- Plays sound.
function Sound:play()
  self.paused = false
  self.source:play()
end
-- Stops sound.
function Sound:stop()
  self.paused = true
  self.source:stop()
end
-- Pauses sound.
function Sound:pause()
  self.paused = true
  self.source:pause()
end
-- Pauses/resumes sound.
-- @param(paused : boolean) True to pause, false to resume.
function Sound:setPaused(paused)
  if paused then
    self:pause()
  else
    self:play()
  end
end

---------------------------------------------------------------------------------------------------
-- Volume & Pitch
---------------------------------------------------------------------------------------------------

-- @param(v : number) New local volume.
function Sound:setVolume(v)
  self.volume = v or self.volume
  self:refreshVolume()
end
-- @param(p : number) New local pitch.
function Sound:setPitch(p)
  self.pitch = p or self.pitch
  self:refreshPitch()
end
-- Updates source's volume according to AudioManager's volume.
function Sound:refreshVolume()
  self.source:setVolume((self.volume / 100) * (AudioManager.volumeSFX / 100))
end
-- Updates source's pitch according to AudioManager's pitch.
function Sound:refreshPitch()
  self.source:setPitch((self.pitch / 100) * (AudioManager.pitchSFX / 100))
end

return Sound
