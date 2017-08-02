
--[[===============================================================================================

WindowCursor
---------------------------------------------------------------------------------------------------
A cursor for button windows.
It's a type of window content.

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')
local Vector = require('core/math/Vector')

local WindowCursor = class()

---------------------------------------------------------------------------------------------------
-- Initialize
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(window : GridWindow) cursor's window
function WindowCursor:init(window)
  self.window = window
  local animData = Database.animOther[Config.gui.cursorAnimID + 1]
  self.anim = Animation.fromData(animData, GUIManager.renderer)
  self.anim.sprite:setTransformation(animData.transform)
  self.anim.sprite:setVisible(false)
  local x, y, w, h = self.anim.sprite.quad:getViewport()
  self.displacement = Vector(-w, 0)
  window.content:add(self)
end

---------------------------------------------------------------------------------------------------
-- Content methods
---------------------------------------------------------------------------------------------------

-- Updates animation.
function WindowCursor:update()
  if self.window.active then
    self.anim:update()
  end
end
-- Updates position to the selected button.
function WindowCursor:updatePosition()
  local button = self.window:currentButton()
  if button then
    self.anim.sprite:setPosition(self.window.position + 
      button:relativePosition() + self.displacement)
  else
    self.anim.sprite:setVisible(false)
  end
end
-- Shows sprite.
function WindowCursor:show()
  self.anim.sprite:setVisible(#self.window.buttonMatrix > 0)
end
-- Hides sprite.
function WindowCursor:hide()
  self.anim.sprite:setVisible(false)
end
-- Removes sprite.
function WindowCursor:destroy()
  self.anim:destroy()
end

return WindowCursor
