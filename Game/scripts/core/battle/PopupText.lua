
--[[===========================================================================

PopupText
-------------------------------------------------------------------------------
A text sprite that is shown in the field with a popup animation.

=============================================================================]]

-- Imports
local Text = require('core/graphics/Text')

-- Alias
local time = love.timer.getDelta

-- Constants
local distance = 32
local speed = 0.5
local properties = {nil, 'center'}

local PopupText = require('core/class'):new()

function PopupText:init(x, y, z)
  self.x = x
  self.y = y
  self.z = z
  self.text = nil
  self.lineCount = 1
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
    _G.Callback.tree:fork(function()
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
      print(sprite.position:toString())
      coroutine.yield()
    end
    while sprite.color.alpha > 0 do
      sprite:setRGBA(nil, nil, nil, sprite.color.alpha - speed * time() * 255)
      coroutine.yield()
    end
    sprite:removeSelf()
  end
end

function PopupText:destroy()
  self.sprite:removeSelf()
end

return PopupText
