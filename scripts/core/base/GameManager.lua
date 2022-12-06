
--[[===============================================================================================

GameManager
---------------------------------------------------------------------------------------------------
Handles basic game flow.

=================================================================================================]]

-- Imports
local TitleGUI = require('core/gui/menu/TitleGUI')

-- Alias
local deltaTime = love.timer.getDelta
local copyTable = util.table.deepCopy
local now = love.timer.getTime

local GameManager = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function GameManager:init()
  local maxWidth = 0
  local modes = love.window.getFullscreenModes(1)
  for i = 1, #modes do
    maxWidth = math.max(maxWidth, modes[i].width)
  end
  self.language = 1
  self.mobileMode = maxWidth <= 900
  self.webMode = false
  self.paused = false
  self.userPaused = false
  self.cleanTime = 300
  self.cleanCount = 0
  self.startedProfi = false
  self.frame = 0
  self.playTime = 0
  self.garbage = setmetatable({}, {__mode = 'v'})
  self.speed = 1
  self.debugMessages = {}
  self.avgStats = {}
  self.stats = { 0, 0, 0, 0, 0, 0 }
  --PROFI = require('core/base/ProFi')
  --require('core/base/Stats').printStats()
end
-- Reads flags from arguments.
-- @param(arg : table) A sequence strings which are command line arguments given to the game.
function GameManager:readArguments(args)
  for _, arg in ipairs(args) do
    if arg == '-editor' then
      self.editor = true
    elseif arg == '-mobile' then
      self.mobileMode = true
    elseif arg == '-web' then
      self.webMode = true
    end
  end
end
-- Starts the game.
function GameManager:start()
  print('Mobile: ' .. tostring(self:isMobile()))
  print('Web: ' .. tostring(self:isWeb()))
  self.playTime = nil
  if self.editor then
    EditorManager:start()
  else
    GUIManager.fiberList:fork(GUIManager.showGUIForResult, GUIManager, TitleGUI(nil))
  end
  print('Game started.')
end
-- Sets current save.
-- @param(save : table) A save table loaded by SaveManager.
function GameManager:setSave(save)
  self.playTime = save.playTime
  self.vars = copyTable(save.vars)
  TroopManager.troopData = copyTable(save.troops)
  TroopManager.playerTroopID = save.playerTroopID
  FieldManager.fieldData = copyTable(save.fields)
  FieldManager.playerState = copyTable(save.playerState)
  if save.battleState then
    -- Load mid-battle.
    BattleManager.params = save.battleState.params
    FieldManager.fiberList:fork(BattleManager.loadBattle, BattleManager, save.battleState)
  else
    FieldManager:loadTransition(save.playerState.transition, save.playerState.field)
  end
end
-- Sets the system config.
-- @param(config : table) A config table loaded by SaveManager.
function GameManager:setConfig(config)
  AudioManager:setBGMVolume(config.volumeBGM)
  AudioManager:setSFXVolume(config.volumeSFX)
  GUIManager.fieldScroll = config.fieldScroll
  GUIManager.windowScroll = config.windowScroll
  InputManager.autoDash = config.autoDash
  InputManager.mouseEnabled = config.useMouse
  InputManager:setArrowMap(config.wasd)
  InputManager:setKeyMap(config.keyMap)
  if config.resolution and self:isDesktop() then
    ScreenManager:setMode(config.resolution)
  end
  if (config.language or 1) ~= self.language then
    self.language = config.language or 1
    Database.loadVocabFiles(self.language)
  end
end

---------------------------------------------------------------------------------------------------
-- Platform
---------------------------------------------------------------------------------------------------

-- Checks if game is running on a standalone desktop version.
-- @ret(boolean)
function GameManager:isDesktop()
  return Config.platform == 0 and not self.webMode and not self.mobileMode
end
-- Checks if game is running on a mobile device (browser or not).
-- @ret(boolean)
function GameManager:isMobile()
  return Config.platform % 2 == 1 or self.mobileMode
end
-- Checks if game is running on a web browser (mobile or not).
-- @ret(boolean)
function GameManager:isWeb()
  return Config.platform >= 2 or self.webMode
end

---------------------------------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------------------------------

-- Game loop.
-- @param(dt : number) The duration of the previous frame.
function GameManager:update(dt)
  local t = os.clock()  
  -- Update game logic.
  if self.restartRequested then
    self:restart()
  end
  if not self.paused then
    if not GUIManager.paused then 
      GUIManager:update()
    end
    if not FieldManager.paused then 
      FieldManager:update() 
    end
    self.frame = self.frame + 1
  end
  if not AudioManager.paused then
    AudioManager:update()
  end
  -- Update input.
  if InputManager.keys['pause']:isTriggered() then
    self.userPaused = not self.userPaused
    self:setPaused(self.userPaused, true, false)
  end
  if not InputManager.paused then
    InputManager:update()
  end
  -- Update profiler.
  self.cleanCount = self.cleanCount + 1
  if self.cleanCount >= self.cleanTime then
    self.cleanCount = 0
    if PROFI then
      self:updateProfi()
    end
    collectgarbage('collect')
  end
  -- Sleep.
  local framerate = Config.fpsMax
  if framerate then
    local sleep = 1 / framerate - (os.clock() - t)
    if sleep > 0 then
      love.timer.sleep(sleep)
    end
  end
end
-- Updates profiler state.
function GameManager:updateProfi()
  if self.startedProfi then
    PROFI:stop()
    PROFI:writeReport('profi.txt')
    self.startedProfi = false
  else
    PROFI:start()
    self.startedProfi = true
  end
end

---------------------------------------------------------------------------------------------------
-- Draw
---------------------------------------------------------------------------------------------------

-- Draws game.
function GameManager:draw()
  if ScreenManager.closed then
    return
  end
  ScreenManager:draw()
  --self:printStats()
  --self:printCoordinates()
  for i = 1, #self.debugMessages do
    love.graphics.print(self.debugMessages[i], 0, 
      love.graphics.getHeight() - i * Fonts.log[3] * 1.2 * ScreenManager.scaleY)
  end
  if self.paused then
    love.graphics.setFont(ResourceManager:loadFont(Fonts.pause, ScreenManager.scaleX))
    love.graphics.printf('PAUSED', 0, 0, ScreenManager:totalWidth(), 'right')
  end
end
-- Prints mouse tile coordinates on the screen.
function GameManager:printCoordinates()
  if not FieldManager.renderer then
    return
  end
  local tx, ty, th = InputManager.mouse:fieldCoord()
  love.graphics.print('(' .. tx .. ',' .. ty .. ',' .. th .. ')', 0, 12)
end
-- Prints FPS and draw call counts on the screen.
function GameManager:printStats()
  self:updateGStats()
  love.graphics.setFont(ResourceManager:loadFont(Fonts.log, ScreenManager.scaleX))
  for i = 1, #self.avgStats do
    love.graphics.print(math.ceil(self.avgStats[i] / 60), (i - 1) * 16 * ScreenManager.scaleX, 0)
  end
end
-- Logs a string on screen on mobile mode. No more than 30 strings are shown at once.
-- @param(str : string) Log message.
function GameManager:log(str)
  print(str)
  if not self:isMobile() then
    return
  end
  --table.insert(self.debugMessages, 1, str)
  if #self.debugMessages > 30 then
    self.debugMessages[31] = nil
  end
end
-- Updates the average graphic stats per second.
function GameManager:updateGStats()
  local gstats = love.graphics.getStats()
  local fps = love.timer.getFPS()
  self.stats[1] = self.stats[1] + fps
  self.stats[2] = self.stats[2] + gstats.drawcalls
  if FieldManager.renderer then
    self.stats[3] = self.stats[3] + FieldManager.renderer.batchDraws
    self.stats[5] = self.stats[5] + FieldManager.renderer.textDraws
  end
  self.stats[4] = self.stats[4] + GUIManager.renderer.batchDraws
  self.stats[6] = self.stats[6] + GUIManager.renderer.textDraws
  if self.frame % 60 == 0 then
    self.avgStats = self.stats
    self.stats = { 0, 0, 0, 0, 0, 0 }
  end
end

---------------------------------------------------------------------------------------------------
-- Pause
---------------------------------------------------------------------------------------------------

-- Pauses entire game.
-- @param(paused : boolean) Pause value.
-- @param(audio : boolean) Also affect audio.
-- @param(input : boolean) Also affect input.
function GameManager:setPaused(paused, audio, input)
  paused = paused or self.userPaused
  self.paused = paused
  if audio then
    AudioManager:setPaused(paused)
  end
  if input then
    InputManager:setPaused(paused)
  end
  if paused then
    self.playTime = self:currentPlayTime()
  else
    SaveManager.loadTime = now()
  end
end

---------------------------------------------------------------------------------------------------
-- Time
---------------------------------------------------------------------------------------------------

-- Gets the current total play time.
-- @ret(number) The time in seconds.
function GameManager:currentPlayTime()
  if not SaveManager.loadTime then
    return 0
  end
  if not self.playTime then
    return nil
  end
  return self.playTime + (now() - SaveManager.loadTime)
end
-- Duration of the last frame.
-- @ret(number) Duration in seconds.
function GameManager:frameTime()
  local dt = deltaTime()
  if Config.fpsMin then
    dt = math.min(dt, 1 / Config.fpsMin)
  end
  return dt * self.speed
end
-- Sets game speed. Does not affect input, only sound and graphics.
-- @parem(speed : number) Speed multiplier.
function GameManager:setSpeed(speed)
  self.speed = speed
  AudioManager:refreshPitch()
end

---------------------------------------------------------------------------------------------------
-- Quit
---------------------------------------------------------------------------------------------------

-- Restarts the game from the TitleGUI.
function GameManager:restart()
  ScreenManager:clear()
  FieldManager = require('core/field/FieldManager')()
  GUIManager = require('core/gui/GUIManager')()
  BattleManager = require('core/battle/BattleManager')()
  ScreenManager:refreshRenderers()
  self:setConfig(SaveManager.config)
  self:start()
  self.restartRequested = false
end
-- Closes game from internal game functions.
function GameManager:quit()
  if _G.Fiber then
    _G.Fiber:wait(15)
  end
  love.event.quit()
end
-- Called when player closes the window.
-- @ret(boolean) False to close the window, true to keep running.
function GameManager:onClose()
  return false
end

return GameManager
