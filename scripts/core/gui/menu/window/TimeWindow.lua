
-- ================================================================================================

--- Small window that shows the play time of the player.
---------------------------------------------------------------------------------------------------
-- @windowmod TimeWindow
-- @extend Window

-- ================================================================================================

-- Imports
local ImageComponent = require('core/gui/widget/ImageComponent')
local TextComponent = require('core/gui/widget/TextComponent')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

-- Class table.
local TimeWindow = class(Window)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Window:createContent`. 
-- @override
function TimeWindow:createContent(width, height)
  Window.createContent(self, width, height)
  local icon = Config.icons.time
  local sprite = icon and icon.id >= 0 and ResourceManager:loadIcon(icon, MenuManager.renderer)
  icon = ImageComponent(sprite, -width / 2 + 4, -height / 2, -1, nil, height)
  self.content:add(icon)
  local pos = Vector(self:paddingX() - width / 2, self:paddingY() - height / 2, -1)
  local text = TextComponent('0', pos, width - self:paddingX() * 2, 'right', Fonts.menu_medium)
  text.sprite.alignY = 'center'
  text.sprite.maxHeight = height - self:paddingY() * 2
  self.content:add(text)
  self.text = text
end
--- Sets the time shown.
-- @tparam number time The current play time in seconds.
function TimeWindow:setTime(time)
  time = math.floor(time)
  if not self.time or self.time ~= time then
    self.time = time
    self.text:setText(string.time(time))
    self.text:redraw()
  end
end
--- Updates play time.
function TimeWindow:update(dt)
  Window.update(self, dt)
  if self.open then
    self:setTime(GameManager:currentPlayTime())
  end
end

return TimeWindow
