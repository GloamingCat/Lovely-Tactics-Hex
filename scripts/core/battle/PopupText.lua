
--[[===============================================================================================

PopupText
---------------------------------------------------------------------------------------------------
A text sprite that is shown in the field with a popup animation.

=================================================================================================]]

-- Imports
local Text = require('core/graphics/Text')

-- Alias
local max = math.max

-- Constants
local distance = 15
local speed = 8
local pause = 15

local PopupText = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor. Starts with no lines.
-- @param(x : number) origin pixel x
-- @param(y : number) origin pixel y
-- @param(z : number) origin pixel z (depth)
function PopupText:init(x, y, renderer)
  self.x = x
  self.y = y
  self.z = renderer.minDepth
  self.text = nil
  self.lineCount = 0
  self.resources = {}
  self.width = 100
  self.align = 'center'
  self.font = nil
  self.renderer = renderer
end

---------------------------------------------------------------------------------------------------
-- Lines
---------------------------------------------------------------------------------------------------

-- Adds a new line.
-- @param(text : string) the text content
-- @param(color : table) the text color (red/green/blue/alpha table)
-- @param(font : Font) the text font
function PopupText:addLine(text, color, font)
  text = '{c' .. color .. '}{f' .. font .. '}' .. text
  local l = self.lineCount
  if l > 0 then
    text = self.text .. '\n' .. text
  end
  self.lineCount = l + 1
  self.text = text
end
-- Add a line to show damage.
-- @param(points : table) result data from skill
function PopupText:addDamage(points)  
  local popupName = 'popup_dmg' .. points.key
  self:addLine(points.value, popupName, popupName)
end
-- Add a line to show heal.
-- @param(points : table) result data from skill
function PopupText:addHeal(points)
  local popupName = 'popup_heal' .. points.key
  self:addLine(points.value, popupName, popupName)
end
-- Add a line to show a status addition.
-- @param(s : Status) The added status. 
function PopupText:addStatus(s)
  local popupName = 'popup_status_add' .. s.data.id
  local color = Color[popupName] and popupName or 'popup_status_add'
  local font = Fonts[popupName] and popupName or 'popup_status_add'
  local name = Vocab.data.status[s.data.key] or s.data.name
  self:addLine('+' .. name, color, font)
end
-- Add lines to show status removal.
-- @param(all : table) Array of Status objects.
function PopupText:removeStatus(all)
  for i = 1, #all do
    local s = all[i]
    local popupName = 'popup_status_remove' .. s.data.id
    local color = Color[popupName] and popupName or 'popup_status_remove'
    local font = Fonts[popupName] and popupName or 'popup_status_remove'
    local name = Vocab.data.status[s.data.key] or s.data.name
    self:addLine('-' .. name, color, font)
  end
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Show the text lines in a pop-up.
-- @param(wait : boolean) True if the execution should wait until the animation finishes 
--  (optional, false by default).
-- @ret(number) The duration in frames.
function PopupText:popup(wait)
  if not self.text then
    return 0
  end
  if not wait then
    Fiber:fork(self.popup, self, true)
    return 60 / speed + pause + 60 / speed * 4
  else
    local p = {self.width, self.align}
    local sprite = Text(self.text, p, self.renderer)
    local y = self.y - sprite:getHeight()
    sprite:setXYZ(self.x - (self.width or 0) / 2, y, self.z)
    local d = 0
    while d < distance do
      d = d + distance * speed * GameManager:frameTime()
      sprite:setXYZ(nil, y - d)
      Fiber:wait()
    end
    Fiber:wait(pause)
    local f = speed / 4 / sprite.color.alpha
    while sprite.color.alpha > 0 do
      local a = max(sprite.color.alpha - f * GameManager:frameTime(), 0)
      sprite:setRGBA(nil, nil, nil, a)
      Fiber:wait()
    end
    sprite:destroy()
    return 0
  end
end
-- Destroys this popup's sprite.
function PopupText:destroy()
  self.sprite:destroy()
end

return PopupText
