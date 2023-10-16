--[[===============================================================================================

@classmod AudioManager
---------------------------------------------------------------------------------------------------
Stores and manages all sound objects in the game. 

=================================================================================================]]

-- Imports.
local List = require('core/datastruct/List')
local Music = require('core/audio/Music')
local Sound = require('core/audio/Sound')

-- Alias.
local max = math.max
local min = math.min
local fileInfo = love.filesystem.getInfo

-- Class table.
local AudioManager = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Initializes with no sound.
function AudioManager:init()
  -- BGM
  self.BGM = nil
  self.fading = 1
  self.fadingSpeed = 0
  self.volumeBGM = 100
  self.pitchBGM = 100
  self.pausedBGM = false
  -- SFX
  self.sfx = List()
  self.volumeSFX = 100
  self.pitchSFX = 100
  self.paused = false
  -- Default sounds
  self.titleTheme = Config.sounds.titleTheme
  self.battleTheme = Config.sounds.battleTheme
  self.victoryTheme = Config.sounds.victoryTheme
  self.gameoverTheme = Config.sounds.gameoverTheme
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Updates BGM and SFX audio.
function AudioManager:update()
  self:updateBGM()
  self:updateSFX()
end
--- Pauses/resumes all Config.sounds.
-- @tparam boolean paused True to paused, false to resume.
function AudioManager:setPaused(paused)
  self.paused = paused
  if self.BGM then
    self.BGM:setPaused(paused)
  end
  for i = 1, #self.sfx do
    self.sfx[i]:setPaused(paused)
  end
end
--- Stops all SFX and tries to resume BGM.
function AudioManager:resetAudio()
  print("Couldn't play sound. Active sounds: " .. love.audio.getActiveSourceCount())
  love.audio.stop()
  if self.BGM then
    if not self.BGM:play() then
      print("Couldn't resume BGM. Active sounds: " .. love.audio.getActiveSourceCount())
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Volume
-- ------------------------------------------------------------------------------------------------

-- @treturn number Volume multiplier for current BGM.
function AudioManager:getBGMVolume()
  return self.volumeBGM
end
-- @tparam number v Volume multiplier for current BGM.
function AudioManager:setBGMVolume(v)
  self.volumeBGM = v
  if self.BGM then
    self.BGM:refreshVolume()
  end
end
-- @treturn number Volume multiplier for current SFX.
function AudioManager:getSFXVolume()
  return self.volumeSFX
end
-- @tparam number v Volume multiplier for current SFX.
function AudioManager:setSFXVolume(v)
  self.volumeSFX = v
  for i = 1, #self.sfx do
    self.sfx[i]:refreshVolume()
  end
end
--- Refreshes BGM and SFX pitch.
function AudioManager:refreshVolume()
  if self.BGM then 
    self.BGM:refreshVolume()
  end
  for i = 1, #self.sfx do
    self.sfx[i]:refreshVolume()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Pitch
-- ------------------------------------------------------------------------------------------------

-- @treturn number Pitch multiplier for current BGM.
function AudioManager:getBGMPitch()
  return self.pitchBGM
end
-- @tparam number p Pitch multiplier for current BGM.
function AudioManager:setBGMPitch(p)
  self.pitchBGM = p
  if self.BGM then 
    self.BGM:refreshPitch()
  end
end
-- @treturn number Pitch multiplier for current SFX.
function AudioManager:getSFXPitch()
  return self.pitchSFX
end
-- @tparam number p Pitch multiplier for current SFX.
function AudioManager:setSFXPitch(p)
  self.pitchSFX = p
  for i = 1, #self.sfx do
    self.sfx[i]:refreshPitch()
  end
end
--- Refreshes BGM and SFX pitch.
function AudioManager:refreshPitch()
  if self.BGM then 
    self.BGM:refreshPitch()
  end
  for i = 1, #self.sfx do
    self.sfx[i]:refreshPitch()
  end
end

-- ------------------------------------------------------------------------------------------------
-- SFX
-- ------------------------------------------------------------------------------------------------

--- Insert a new SFX in the list and plays it.
-- @tparam table|string sfx Table with file's name (from audio/sfx folder), volume and pitch,
--  or the name of the sound type in the Config.sounds table.
function AudioManager:playSFX(sfx)
  local volume = sfx.volume or 100
  local pitch = sfx.pitch or 100
  if Config.sounds[sfx.name] then
    sfx = Config.sounds[sfx.name]
    volume = volume * (sfx.volume or 100) / 100
    pitch = pitch * (sfx.pitch or 100) / 100
  end
  if fileInfo(Project.audioPath .. sfx.name) then
    local sound = Sound(sfx.name, volume, pitch)
    self.sfx:add(sound)
    if not sound:play() then
      self:resetAudio()
    end
  else
    print("Missing SFX: " ..  Project.audioPath .. sfx.name)
  end
end
--- Updates SFX list (remove all finished SFX).
function AudioManager:updateSFX()
  if self.sfx[1] then
    self.sfx:conditionalRemove(self.sfx[1].isFinished)
  end
end

-- ------------------------------------------------------------------------------------------------
-- BGM - General
-- ------------------------------------------------------------------------------------------------

--- [COROUTINE] Stops current playing BGM (if any) and starts a new one.
-- @tparam table bgm Table with file's name (from audio/bgm folder), volume and pitch.
-- @tparam number time The duration of the fading transition (optinal, 0 by default).
-- @tparam boolean wait Yields until the fading animation concludes (optional, false by defaul).
function AudioManager:playBGM(bgm, time, wait)
  local volume = bgm.volume or 100
  local pitch = bgm.pitch or 100
  if Config.sounds[bgm.name] then
    bgm = Config.sounds[bgm.name]
    volume = volume * (bgm.volume or 100) / 100
    pitch = pitch * (bgm.pitch or 100) / 100
  end
  if self.BGM then
    if self.BGM.name == bgm.name then
      -- Same music
      self:fadein(time or 0, wait)
      return
    end
    self.BGM:stop()
  end
  if fileInfo(Project.audioPath .. bgm.name) then
    self.BGM = Music(bgm.name, volume, pitch, bgm.intro, bgm.loop)
    if not self.BGM:play() then
      self:resetAudio()
    end
    self.pausedBGM = false
    self:fadein(time or 0, wait)
  else
    print("Missing BGM: " ..  Project.audioPath .. bgm.name)
  end
end
-- @tparam number time The duration of the fading transition.
-- @tparam boolean wait Yields until the fading animation concludes.
function AudioManager:resumeBGM(time, wait)
  if self.pausedBGM then
    if self.BGM then
      self.BGM:play()
    end
    self.pausedBGM = false
    self:fadein(time, wait)
  end
end
--- [COROUTINE] Paused current BGM.
-- @tparam number time Fade-out time.
-- @tparam boolean wait Wait until the end of the fading.
-- @treturn Music Current playing BGM (if any).
function AudioManager:pauseBGM(time, wait)
  if self.BGM then
    self.pausedBGM = true
    self:fadeout(time, wait)
    return self.BGM
  end
end

-- ------------------------------------------------------------------------------------------------
-- BGM - Update
-- ------------------------------------------------------------------------------------------------

--- Updates fading and BGMs.
function AudioManager:updateBGM()
  if self.BGM then
    self.BGM:update()
  else
    return
  end
  if self.fadingSpeed > 0 and self.fading < 1 or self.fadingSpeed < 0 and self.fading > 0 then
    self.fading = min(1, max(0, self.fading + GameManager:frameTime() * self.fadingSpeed))
    self.BGM:refreshVolume()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Fading
-- ------------------------------------------------------------------------------------------------

--- [COROUTINE] Decreases the BGM volume slowly.
-- @tparam number time The duration of the fading.
-- @tparam boolean wait True to only return when the fading finishes.
function AudioManager:fadeout(time, wait)
  if time and time > 0 then
    self.fading = 1
    self.fadingSpeed = -60 / time
    if wait then
      self:waitForBGMFading()
    end
  else
    self.fading = 0
    self.fadingSpeed = 0
    if self.BGM then
      self.BGM:refreshVolume()
    end
  end
end
--- [COROUTINE] Increases the BGM volume slowly.
-- @tparam number time The duration of the fading.
-- @tparam boolean wait True to only return when the fading finishes.
function AudioManager:fadein(time, wait)
  if time and time > 0 then
    self.fading = 0
    self.fadingSpeed = 60 / time
    if wait then
      self:waitForBGMFading()
    end
  else
    self.fading = 1
    self.fadingSpeed = 0
    if self.BGM then
      self.BGM:refreshVolume()
    end
  end
end
--- [COROUTINE] Waits until the fading value is 1.
function AudioManager:waitForBGMFading()
  local fiber = _G.Fiber
  if self.fadingFiber then
    self.fadingFiber:interrupt()
  end
  self.fadingFiber = fiber
  while self.fading < 1 and self.fading > 0 do
    Fiber:wait()
  end
  if fiber:running() then
    self.fadingFiber = nil
  end
end

return AudioManager
