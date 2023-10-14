
--[[===============================================================================================

TimeWindow
---------------------------------------------------------------------------------------------------
Small window that shows the play time of the player.

=================================================================================================]]

-- Imports
local SimpleImage = require('core/gui/widget/SimpleImage')
local SimpleText = require('core/gui/widget/SimpleText')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

local TimeWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides Window:createContent.
function TimeWindow:createContent(width, height)
  Window.createContent(self, width, height)
  local icon = Config.icons.time
  local sprite = icon and icon.id >= 0 and ResourceManager:loadIcon(icon, GUIManager.renderer)
  icon = SimpleImage(sprite, -width / 2 + 4, -height / 2, -1, nil, height)
  self.content:add(icon)
  local pos = Vector(self:paddingX() - width / 2, self:paddingY() - height / 2, -1)
  local text = SimpleText('0', pos, width - self:paddingX() * 2, 'right', Fonts.gui_medium)
  text.sprite.alignY = 'center'
  text.sprite.maxHeight = height - self:paddingY() * 2
  self.content:add(text)
  self.text = text
end
-- Sets the time shown.
-- @param(time : number) The current play time in seconds.
function TimeWindow:setTime(time)
  time = math.floor(time)
  if not self.time or self.time ~= time then
    self.time = time
    self.text:setText(string.time(time))
    self.text:redraw()
  end
end
-- Updates play time.
function TimeWindow:update(dt)
  Window.update(self, dt)
  if self.open then
    self:setTime(GameManager:currentPlayTime())
  end
end

return TimeWindow
