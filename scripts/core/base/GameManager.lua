
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
  self.paused = false
  self.cleanTime = 300
  self.cleanCount = 0
  self.startedProfi = false
  self.frame = 0
  self.playTime = 0
  self.garbage = setmetatable({}, {__mode = 'v'})
  self.speed = 1
  self.debugMessages = {}
  --PROFI = require('core/base/ProFi')
  --require('core/base/Stats').printStats()
end
-- Reads flags from arguments.
-- @param(arg : table) A sequence strings which are command line arguments given to the game.
function GameManager:readArguments(args)
  for _, arg in ipairs(args) do
    if arg == '-editor' then
      self.editor = true
    end
  end
end
-- Starts the game.
function GameManager:start()
  self.fpsFont = ResourceManager:loadFont(Fonts.fps)
  if self.editor then
    EditorManager:start()
  else
    GUIManager.fiberList:fork(GUIManager.showGUIForResult, GUIManager, TitleGUI(nil))
  end
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
  ScreenManager:setMode(config.resolution)
end

---------------------------------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------------------------------

-- Game loop.
-- @param(dt : number) The duration of the previous frame.
function GameManager:update(dt)
  local t = os.clock()  
  -- Update game logic.
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
    self:setPaused(not self.paused, true, false)
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
  local framerate = Config.screen.fpsLimit
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
  love.graphics.setFont(self.fpsFont)
  self:printStats()
  --self:printCoordinates()
  if self.paused then
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
  love.graphics.print(love.timer.getFPS())
  love.graphics.print(ScreenManager.drawCalls, 32, 0)
  for i = 1, #self.debugMessages do
    love.graphics.print(self.debugMessages[i], 0, 24 * i)
  end
end
-- Logs a string on screen. No more than 10 strings are shown at once.
-- @param(str : string) Log.
function GameManager:print(str)
  table.insert(self.debugMessages, 1, str)
  if #self.debugMessages > 10 then
    self.debugMessages[11] = nil
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
  return self.playTime + (now() - SaveManager.loadTime)
end
-- Duration of the last frame.
-- @ret(number) Duration in seconds.
function GameManager:frameTime()
  local dt = deltaTime()
  if dt > 0.05 then
    return 0.05 * self.speed
  else
    return dt * self.speed
  end
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
  self:start()
end
-- Closes game.
function GameManager:quit(force)
  if _G.Fiber then
    _G.Fiber:wait(15)
  end
  self.forceQuit = force
  love.event.quit()
end
-- Called when player closes the window.
-- @ret(boolean) False to close the window, true to keep running.
function GameManager:onClose()
  return false
end

return GameManager
