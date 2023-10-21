
-- ================================================================================================

--- Print game statistics for debugging.
---------------------------------------------------------------------------------------------------
-- @plugin PrintStats

-- ================================================================================================

-- Imports
local GameManager = require('core/base/GameManager')

-- Rewrites
local GameManager_init = GameManager.init
local GameManager_updateManagers = GameManager.updateManagers
local GameManager_draw = GameManager.draw
local GameManager_updateProfi = GameManager.updateProfi

-- Parameters
KeyMap.main['stats'] = args.stats
KeyMap.main['profi'] = args.profi
local countdown = args.countdown

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Rewrites `GameManager:init`.
-- @rewrite
function GameManager:init()
  GameManager_init(self)
  self.profiPaused = false
  self.profiCount = 0
  self.keepProfi = true
  self.avgStats = {}
  self.stats = { 0, 0, 0, 0, 0, 0 }
end
--- Rewrites `GameManager:updateManagers`.
-- @rewrite
function GameManager:updateManagers(dt)
  if InputManager.keys['stats']:isTriggered() then
    self.statsVisible = not self.statsVisible
  end
  if InputManager.keys['profi']:isTriggered() then
    self:toggleProfi()
  end
  if self.profiPaused and countdown then
    if os.clock() - PROFI.startTime > countdown then
      self:toggleProfi()
    end
  end
  GameManager_updateManagers(self, dt)
end
--- Rewrites `GameManager:draw`.
-- @rewrite
function GameManager:draw()
  GameManager_draw(self)
  if self.statsVisible then
    love.graphics.setFont(ResourceManager:loadFont(Fonts.log, ScreenManager.scaleX))
    self:updateGStats()
    self:printStats()
    if PROFI then
      if self.profiPaused then
        love.graphics.print('ProFi: On', 0, 0)
      elseif self.keepProfi then
        love.graphics.print('ProFi: Auto', 0, 0)
      else
        love.graphics.print('ProFi: Off', 0, 0)
      end
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Stats
-- ------------------------------------------------------------------------------------------------

--- Pauses default ProFi behavior if it was activated by button.
function GameManager:updateProfi()
  if not self.profiPaused and self.keepProfi then
    GameManager_updateProfi(self)
  end
end
--- Activate/deactivate ProFi by button.
function GameManager:toggleProfi()
  if not PROFI then
    self.keepProfi = false
    PROFI = require('core/base/ProFi')
  end
  if self.profiPaused then
    PROFI:stop()
    PROFI:writeReport('profi' .. tostring(self.profiCount) .. '.txt')
    self.profiCount = self.profiCount + 1
    self.profiPaused = false
  else
    PROFI:start()
    self.profiPaused = true
  end
end

-- ------------------------------------------------------------------------------------------------
-- Stats
-- ------------------------------------------------------------------------------------------------

--- Prints FPS and draw call counts on the screen.
function GameManager:printStats()
  local tab = 60 * ScreenManager.scaleX
  local line = 6 * ScreenManager.scaleY
  local x = love.graphics.getWidth() - 10 * ScreenManager.scaleX
  local y = love.graphics.getHeight()
  love.graphics.print("FPS:", x - tab, y - 6 * line)
  love.graphics.print("Total draw calls:", x - tab, y - 5 * line)
  love.graphics.print("Batch draw calls (field):", x - tab, y - 4 * line)
  love.graphics.print("Text draw calls (field):", x - tab, y - 3 * line)
  love.graphics.print("Batch draw calls (UI):", x - tab, y - 2 * line)
  love.graphics.print("Text draw calls (UI):", x - tab, y - line)
  for i = 1, #self.avgStats do
    love.graphics.print(math.ceil(self.avgStats[i] / 60), x, y - (7 - i) * line)
  end
  if not FieldManager.renderer then
    return
  end
  local tx, ty, th = InputManager.mouse:fieldCoord()
  love.graphics.print('(' .. tx .. ',' .. ty .. ',' .. th .. ')', 0, y - line)
end
--- Updates the average graphic stats per second.
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
