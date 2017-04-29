
--[[===========================================================================

PopupText
-------------------------------------------------------------------------------
A text sprite that is shown in the field with a popup animation.

=============================================================================]]

-- Imports
local Text = require('core/graphics/Text')

-- Alias
local time = love.timer.getDelta
local max = math.max

-- Constants
local distance = 15
local speed = 8
local pause = 30
local properties = {nil, 'left'}

local PopupText = class()

function PopupText:init(x, y, z)
  self.x = x
  self.y = y
  self.z = z
  self.text = nil
  self.lineCount = 0
  self.resources = {}
end

function PopupText:addLine(text, color, font)
  local l = self.lineCount
  local cl, fl = 'c' .. l, 'f' .. l
  text = '{' .. cl .. '}{' .. fl .. '}' .. text
  if l > 0 then
    text = self.text .. '\n' .. text
  end
  self.lineCount = l + 1
  self.text = text
  self.resources[cl] = color
  self.resources[fl] = font
end

function PopupText:popup(wait)
  if not self.text then
    return
  end
  if not wait then
    _G.Fiber:fork(function()
      self:popup(true)
    end)
  else
    local sprite = Text(self.text, self.resources, properties, FieldManager.renderer)
    sprite:setXYZ(self.x, self.y, self.z)
    sprite:setCenterOffset()
    local d = 0
    while d < distance do
      d = d + distance * speed * time()
      sprite:setXYZ(nil, self.y - d)
      coroutine.yield()
    end
    _G.Fiber:wait(pause)
    local f = 100 / (sprite.color.alpha / 255)
    while sprite.color.alpha > 0 do
      local a = max(sprite.color.alpha - speed * time() * f, 0)
      sprite:setRGBA(nil, nil, nil, a)
      coroutine.yield()
    end
    sprite:removeSelf()
  end
end

function PopupText:destroy()
  self.sprite:destroy()
end

return PopupText
