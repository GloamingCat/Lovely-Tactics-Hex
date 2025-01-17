
-- ================================================================================================

--- A class representing a sound.
---------------------------------------------------------------------------------------------------
-- @iomod Sound

-- ================================================================================================

-- Class table.
local Sound = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam string name Name of the file from the audio folder.
-- @tparam number volume Initial volume (from 0 to 100).
-- @tparam number pitch Initial pitch (from 0 to 100).
function Sound:init(name, volume, pitch)
  self.name = name
  self:initSource(ResourceManager:loadSFX(name), volume, pitch)
end
--- Initializes source.
-- @tparam Source source The audio source.
-- @tparam number volume Initial volume (from 0 to 100).
-- @tparam number pitch Initial pitch (from 0 to 100).
function Sound:initSource(source, volume, pitch)
  self.volume = volume or 100
  self.pitch = pitch or 100
  self.source = source
  self.source:seek(0)
  self:refreshVolume()
  self:refreshPitch()
  self.paused = true
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Tells if the sound already ended.
-- @treturn boolean True if it stopped playing (but it's not paused).
function Sound:isFinished()
  return not self.source:isPlaying() and not self.paused
end
--- Gets the duration in a given unit.
-- @tparam[opt="seconds"] string unit Either "seconds" or "samples".
-- @treturn number The duration in the given unit.
function Sound:getDuration(unit)
  return self.source:getDuration(unit)
end

-- ------------------------------------------------------------------------------------------------
-- Playing
-- ------------------------------------------------------------------------------------------------

--- Plays sound.
function Sound:play()
  self.paused = false
  if not self.source:isPlaying() then
    return self.source:play()
  end
end
--- Stops sound.
function Sound:stop()
  self.paused = true
  self.source:stop()
end
--- Pauses sound.
function Sound:pause()
  self.paused = true
  self.source:pause()
end
--- Pauses/resumes sound.
-- @tparam boolean paused True to pause, false to resume.
function Sound:setPaused(paused)
  if paused then
    self:pause()
  else
    self:play()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Volume & Pitch
-- ------------------------------------------------------------------------------------------------

--- Sets the sound's volume.
-- @tparam number v New local volume (0-1).
function Sound:setVolume(v)
  self.volume = v or self.volume
  self:refreshVolume()
end
--- Sets the sound's pitch.
-- @tparam number p New local pitch (0-1).
function Sound:setPitch(p)
  self.pitch = p or self.pitch
  self:refreshPitch()
end
--- Updates source's volume according to AudioManager's volume.
function Sound:refreshVolume()
  self.source:setVolume((self.volume / 100) * (AudioManager.volumeSFX / 100))
end
--- Updates source's pitch according to AudioManager's pitch.
function Sound:refreshPitch()
  self.source:setPitch((self.pitch / 100) * (AudioManager.pitchSFX / 100) * GameManager.speed)
end

return Sound
