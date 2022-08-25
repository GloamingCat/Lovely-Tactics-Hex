
--[[===============================================================================================

GameMouse
---------------------------------------------------------------------------------------------------
Entity that represents game's mouse.
Buttons:
1 => left | 2 => right | 3 => middle

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local GameKey = require('core/input/GameKey')

-- Alias
local timer = love.timer
local round = math.round
local pixel2Tile = math.field.pixel2Tile

-- Constants
local hideTime = 2
local pph = Config.grid.pixelsPerHeight
local dph = Config.grid.depthPerHeight
local dpy = Config.grid.depthPerY / Config.grid.tileH

local GameMouse = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function GameMouse:init()
  self.position = Vector(0, 0)
  self.lastMove = 0
  self.active = false
  self.buttons = {}
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Checks if player is using keyboard and updates state.
function GameMouse:update()
  self.moved = false
  if InputManager.usingKeyboard or (timer.getTime() - self.lastMove) > hideTime then
    self:hide()
  end
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Called when player clicks.
-- @param(id : number) button type, from 1 to 3
function GameMouse:onPress(id)
  if not InputManager.usingKeyboard then
    self:show()
  end
end
-- Called when player releases button.
-- @param(id : number) button type, from 1 to 3
function GameMouse:onRelease(id)
end
-- Called when player moves cursor.
-- @param(x : number) current cursor x coordinate
-- @param(y : number) current cursor y coordinate
function GameMouse:onMove(x, y)
  self.position:set(x, y)
  self.moved = true
  self:show()
end

---------------------------------------------------------------------------------------------------
-- Cursor's graphics
---------------------------------------------------------------------------------------------------

-- Shows cursor.
function GameMouse:show()
  self.lastMove = timer.getTime()
  self.active = true
  love.mouse.setVisible(true)
end
-- Hides and deactivates cursor.
function GameMouse:hide()
  if Config.platform ~= 1 then
    self.active = false
    love.mouse.setVisible(false)
  end
end

---------------------------------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------------------------------

-- Gets the tile that the mouse is over.
-- @param(h : number) The height of the tile layer (1 by default).
-- @ret(number) Tile x.
-- @ret(number) Tile y.
-- @ret(number) Tile height.
function GameMouse:fieldCoord(h)
  h = h or 1
  local pos = self.position
  local wx, wy = ScreenManager:screen2World(FieldManager.renderer, pos.x, pos.y)
  local tx, ty, th = pixel2Tile(wx, wy, -(h - 1) * (pph + dph) - wy * dpy)
  return round(tx), round(ty), round(th)
end
-- Gets the pixel in the GUI that the mouse is over.
-- @ret(number) Pixel x.
-- @ret(number) Pixel y.
function GameMouse:guiCoord()
  local pos = self.position
  local wx, wy = ScreenManager:screen2World(GUIManager.renderer, pos.x, pos.y)
  return round(wx), round(wy)
end

return GameMouse
