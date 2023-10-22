
-- ================================================================================================

--- Entity that represents game's mouse.
-- Used in `InputManager`.
---------------------------------------------------------------------------------------------------
-- @iomod GameMouse

-- ================================================================================================

-- Imports
local Vector = require('core/math/Vector')
local GameKey = require('core/input/GameKey')

-- Alias
local timer = love.timer
local round = math.round
local pixel2Tile = math.field.pixel2Tile

-- Constants
local pph = Config.grid.pixelsPerHeight
local dph = Config.grid.depthPerHeight
local dpy = Config.grid.depthPerY / Config.grid.tileH

-- Class table.
local GameMouse = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function GameMouse:init()
  self.hideTime = not GameManager:isMobile() and 2 or math.huge
  self.position = Vector(0, 0)
  self.lastMove = 0
  self.active = GameManager:isMobile()
  self.buttons = {}
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Checks if player is using keyboard and updates state.
function GameMouse:update()
  self.moved = false
  if InputManager.usingKeyboard or (timer.getTime() - self.lastMove) > self.hideTime then
    self:hide()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Input handlers
-- ------------------------------------------------------------------------------------------------

--- Called when player clicks.
-- @tparam number id Button type, from 1 to 3.
function GameMouse:onPress(id)
  if not InputManager.usingKeyboard then
    self:show()
  end
end
--- Called when player releases button.
-- @tparam number id Button type, from 1 to 3.
function GameMouse:onRelease(id)
end
--- Called when player moves cursor.
-- @tparam number x Current cursor x coordinate.
-- @tparam number y Current cursor y coordinate.
function GameMouse:onMove(x, y)
  self.position:set(x, y)
  self.moved = true
  self:show()
end

-- ------------------------------------------------------------------------------------------------
-- Cursor's graphics
-- ------------------------------------------------------------------------------------------------

--- Shows cursor.
function GameMouse:show()
  self.lastMove = timer.getTime()
  self.active = true
  love.mouse.setVisible(true)
end
--- Hides and deactivates cursor.
function GameMouse:hide()
  if not GameManager:isMobile() then
    self.active = false
    love.mouse.setVisible(false)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Position
-- ------------------------------------------------------------------------------------------------

--- Gets the tile that the mouse is over.
-- @tparam number h The height of the tile layer (1 by default).
-- @treturn number Tile x.
-- @treturn number Tile y.
-- @treturn number Tile height.
function GameMouse:fieldCoord(h)
  h = h or 1
  local pos = self.position
  local wx, wy = ScreenManager:screen2World(FieldManager.renderer, pos.x, pos.y)
  local tx, ty, th = pixel2Tile(wx, wy, -(h - 1) * (pph + dph) - wy * dpy)
  return round(tx), round(ty), round(th)
end
--- Gets the pixel in the GUI that the mouse is over.
-- @treturn number Pixel x.
-- @treturn number Pixel y.
function GameMouse:guiCoord()
  local pos = self.position
  local wx, wy = ScreenManager:screen2World(GUIManager.renderer, pos.x, pos.y)
  return round(wx), round(wy)
end

return GameMouse
