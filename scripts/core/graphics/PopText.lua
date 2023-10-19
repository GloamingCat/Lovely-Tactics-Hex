
-- ================================================================================================

--- A text sprite that is shown in the field with a pop-up animation.
---------------------------------------------------------------------------------------------------
-- @classmod PopText

-- ================================================================================================

-- Imports
local Text = require('core/graphics/Text')

-- Alias
local max = math.max

-- Class table.
local PopText = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. Starts with no lines.
-- @tparam number x Origin pixel x.
-- @tparam number y Origin pixel y.
-- @tparam Renderer renderer The target renderer.
function PopText:init(x, y, renderer)
  self.x = x
  self.y = y
  self.z = renderer.minDepth
  self.text = nil
  self.lineCount = 0
  self.resources = {}
  self.width = 100
  self.align = 'center'
  self.font = nil
  self.distance = 15
  self.speed = 8
  self.pause = 15
  self.renderer = renderer
end

-- ------------------------------------------------------------------------------------------------
-- Lines
-- ------------------------------------------------------------------------------------------------

--- Adds a new line.
-- @tparam string text The text content.
-- @tparam table color The text color (red/green/blue/alpha table).
-- @tparam Font font The text font.
function PopText:addLine(text, color, font)
  text = '{c' .. color .. '}{f' .. font .. '}' .. text
  local l = self.lineCount
  if l > 0 then
    text = self.text .. '\n' .. text
  end
  self.lineCount = l + 1
  self.text = text
end
--- Add a line to show damage.
-- @tparam table points Result data from skill.
function PopText:addDamage(points)  
  local popupName = 'popup_dmg' .. points.key
  self:addLine(points.value, popupName, popupName)
end
--- Add a line to show heal.
-- @tparam table points Result data from skill.
function PopText:addHeal(points)
  local popupName = 'popup_heal' .. points.key
  self:addLine(points.value, popupName, popupName)
end
--- Add a line to show a status addition.
-- @tparam Status s The added status.
function PopText:addStatus(s)
  local popupName = 'popup_status_add' .. s.data.id
  local color = Color[popupName] and popupName or 'popup_status_add'
  local font = Fonts[popupName] and popupName or 'popup_status_add'
  local name = Vocab.data.status[s.data.key] or s.data.name
  self:addLine('+' .. name, color, font)
end
--- Add lines to show status removal.
-- @tparam table all Array of Status objects.
function PopText:removeStatus(all)
  for i = 1, #all do
    local s = all[i]
    local popupName = 'popup_status_remove' .. s.data.id
    local color = Color[popupName] and popupName or 'popup_status_remove'
    local font = Fonts[popupName] and popupName or 'popup_status_remove'
    local name = Vocab.data.status[s.data.key] or s.data.name
    self:addLine('-' .. name, color, font)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Show the text lines.
-- @coroutine pop
-- @tparam number dir 1 to pop up, -1 to pop down.
function PopText:pop(dir)
  local p = {self.width, self.align}
  local sprite = Text(self.text, p, self.renderer)
  local y = self.y - dir * sprite:getHeight()
  sprite:setXYZ(self.x - (self.width or 0) / 2, y, self.z)
  local d = 0
  while d < self.distance do
    d = d + self.distance * self.speed * GameManager:frameTime()
    sprite:setXYZ(nil, y - dir * d)
    Fiber:wait()
  end
  Fiber:wait(self.pause)
  local f = self.speed / 4 / sprite.color.alpha
  while sprite.color.alpha > 0 do
    local a = max(sprite.color.alpha - f * GameManager:frameTime(), 0)
    sprite:setRGBA(nil, nil, nil, a)
    Fiber:wait()
  end
  sprite:destroy()
end
--- Show the text lines.
-- @coroutine popUp
-- @tparam boolean wait True if the execution should wait until the animation finishes 
--  (optional, false by default).
-- @treturn number The duration in frames.
function PopText:popUp(wait)
  if not self.text then
    return 0
  end
  if not wait then
    Fiber:fork(self.pop, self, 1)
    return 60 / self.speed + self.pause + 60 / self.speed * 4
  else
    self:pop(1)
    return 0
  end
end
--- Show the text lines.
-- @coroutine popDown
-- @tparam boolean wait True if the execution should wait until the animation finishes 
--  (optional, false by default).
-- @treturn number The duration in frames.
function PopText:popDown(wait)
  if not self.text then
    return 0
  end
  if not wait then
    Fiber:fork(self.pop, self, -1)
    return 60 / self.speed + self.pause + 60 / self.speed * 4
  else
    self:pop(-1)
    return 0
  end
end
--- Destroys the text sprite.
function PopText:destroy()
  self.sprite:destroy()
end

return PopText
