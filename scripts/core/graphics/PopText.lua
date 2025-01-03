
-- ================================================================================================

--- A text sprite that is shown with a pop-up animation.
---------------------------------------------------------------------------------------------------
-- @animmod PopText
-- @extend Text

-- ================================================================================================

-- Imports
local Text = require('core/graphics/Text')

-- Alias
local max = math.max

-- Class table.
local PopText = class(Text)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. Starts with no lines.
-- @tparam FieldManager|MenuManager manager The target manager.
-- @tparam[opt] number x Origin pixel x.
-- @tparam[opt] number y Origin pixel y.
function PopText:init(manager, x, y)
  Text.init(self, "", {}, manager.renderer)
  self.text = nil
  self.lineCount = 0
  self.resources = {}
  self.width = 100
  self.align = 'center'
  self.font = nil
  self.distance = 15 -- pixels
  self.speed = 8 -- pixels / second
  self.pause = 0.25 -- seconds
  self.fadeDuration = 2 -- seconds
  self.time = -1
  manager.updateList:add(self)
  self:setXYZ(x, y, manager.renderer.minDepth)
  self:setVisible(false)
end

-- ------------------------------------------------------------------------------------------------
-- Content
-- ------------------------------------------------------------------------------------------------

--- Adds a new line.
-- @tparam string text The text content.
-- @tparam string color The name of the text color.
-- @tparam string font The name of the text font.
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

--- Updates pop-up or pop-down animation.
-- @tparam number dt The duration of the previous frame.
function PopText:update(dt)
  if self.time < 0 then
    return
  end
  if self.time < 1 then
    -- Moving phase
    self.time = self.time + self.speed * dt
    if self.time >= 1 then
      self.time = 1
      self.speed = self.fadeDuration / self.color.a
    end
    self:setXYZ(nil, self.destination - self.direction * self.time * self.distance)
  else
    if self.time < 1 + self.pause then
      -- Wait phase
      self.time = self.time + dt
    elseif self.color.a > 0 then
      -- Color phase
      local a = max(self.color.a - self.speed * dt, 0)
      self:setRGBA(nil, nil, nil, a)
    else
      self.destroyed = true
      self.time = -1
    end
  end
end
--- Show the text lines.
-- @coroutine
-- @tparam number dir 1 to pop up, -1 to pop down.
function PopText:pop(dir)
  self:setMaxWidth(self.width)
  self:setAlignX(self.align)
  self:setText(self.text)
  self:setXYZ(self.position.x - (self.width or 0) / 2, nil)
  self:setVisible(true)
  self.direction = dir
  self.time = 0
  self.destination = self.position.y - self.direction * self:getHeight()
end
--- Show the text lines.
-- @coroutine
-- @tparam[opt] boolean wait Flag to wait until the animation finishes.
-- @treturn number The duration in frames until the animation finishes.
function PopText:popUp(wait)
  if not self.text then
    return 0
  end
  self:pop(1)
  if wait then
    _G.Fiber:waitUntil(self.isFinished, self)
    return 0
  else
    return 60 / self.speed + self.pause + 60 / self.speed * 4
  end
end
--- Show the text lines.
-- @coroutine
-- @tparam[opt] boolean wait Flag to wait until the animation finishes.
-- @treturn number The duration in frames until the animation finishes.
function PopText:popDown(wait)
  if not self.text then
    return 0
  end
  self:pop(-1)
  if wait then
    _G.Fiber:waitUntil(self.isFinished, self)
    return 0
  else
    return 60 / self.speed + self.pause + 60 / self.speed * 4
  end
end
--- Whether the animation finished.
-- @treturn boolean
function PopText:isFinished()
  return self.color.a == 0
end
--- Whether the animation started but not finished.
-- @treturn boolean
function PopText:isPlaying()
  return self.color.a > 0 and self.time >= 0
end
-- For debugging.
function PopText:__tostring()
  if self.text then
    return 'PopText: "' .. self.text .. '"' 
  else
    return 'PopText: nil'
  end
end

return PopText
