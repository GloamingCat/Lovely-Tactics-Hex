
--[[===============================================================================================

GameMouse
---------------------------------------------------------------------------------------------------
Entity that represents game's mouse.
Buttons:
1 => left
2 => right
3 => middle

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local GameKey = require('core/input/GameKey')

-- Alias
local timer = love.timer

-- Constants
local hideTime = 3

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
  self.buttons[1] = GameKey()
  self.buttons[2] = GameKey()
  self.buttons[3] = GameKey()
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Checks if player is using keyboard and updates state.
function GameMouse:update()
  if InputManager.usingKeyboard or (timer.getTime() - self.lastMove) > hideTime then
    self:hide()
  else
    for i = 1, 3 do
      if self.buttons[i].pressState == 2 then
        self.buttons[i].pressState = 1
      end
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Called when player clicks.
-- @param(id : number) button type, from 1 to 3
function GameMouse:onPress(id)
  self.buttons[id]:onPress()
  self.active = true
  self:show()
end

-- Called when player releases button.
-- @param(id : number) button type, from 1 to 3
function GameMouse:onRelease(id)
  self.buttons[id]:onRelease()
end

-- Called when player moves cursor.
-- @param(x : number) current cursor x coordinate
-- @param(y : number) current cursor y coordinate
function GameMouse:onMove(x, y)
  self.position:set(x, y)
  self:show()
end

---------------------------------------------------------------------------------------------------
-- Cursor's graphics
---------------------------------------------------------------------------------------------------

-- Shows cursor.
function GameMouse:show()
  self.lastMove = timer.getTime()
  love.mouse.setVisible(true)
end

-- Hides and deactivates cursor.
function GameMouse:hide()
  self.active = false
  love.mouse.setVisible(false)
end

return GameMouse
