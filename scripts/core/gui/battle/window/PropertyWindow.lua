
--[[===============================================================================================

PropertyWindow
---------------------------------------------------------------------------------------------------
Window that opens in Action GUI to show a property of the current character.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')
local SimpleText = require('core/gui/widget/SimpleText')

local PropertyWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides Window:init.
function PropertyWindow:init(GUI)
  local w, h, m = 90, 30, GUI:windowMargin()
  Window.init(self, GUI, w, h, Vector(ScreenManager.width / 2 - w / 2 - m, 
      ScreenManager.height / 2 - h / 2 - m))
end
-- Overrides Window:createContent.
-- Creates step text.
function PropertyWindow:createContent(width, height)
  Window.createContent(self, width, height)
  local w = self.width - self:paddingX() * 2
  local h = self.height - self:paddingY() * 2
  local pos = Vector(self:paddingX() - self.width / 2, self:paddingY() - self.height / 2)
  local text = SimpleText('', pos, w)
  local value = SimpleText('', pos, w)
  text:setAlign('left', 'center')
  text:setMaxHeight(h)
  value:setAlign('right', 'center')
  value:setMaxHeight(h)
  self.txtLabel = text
  self.txtValue = value
  self.content:add(text)
  self.content:add(value)
end
-- Sets content.
-- @param(term : string) Property label.
-- @param(value : unknown) Property value.
function PropertyWindow:setProperty(term, value)
  self.txtLabel:setTerm('{%' .. term .. '}:', term .. ':')
  self.txtLabel:redraw()
  self.txtValue:setText(tostring(value))
  self.txtValue:redraw()
end
-- @ret(string) String representation (for debugging).
function PropertyWindow:__tostring()
  return 'Property Window'
end

return PropertyWindow
