
local Animation = require('core/graphics/Animation')
local Vector = require('core/math/Vector')

--[[===========================================================================

A cursor for button windows.

=============================================================================]]

local ButtonCursor = require('core/class'):new()

function ButtonCursor:init(window)
  self.window = window
  local animData = Database.animOther[Config.gui.cursorAnimID + 1]
  self.anim = Animation.fromData(animData, GUIManager.renderer)
  self.anim.sprite:setTransformation(animData.transform)
  self.anim.sprite:setVisible(false)
  local x, y, w, h = self.anim.sprite.quad:getViewport()
  self.displacement = Vector(-w, 0)
  window.content:add(self)
end

-- Updates animation.
function ButtonCursor:update()
  self.anim:update()
end

-- Updates position to the selected button.
function ButtonCursor:updatePosition()
  local button = self.window:currentButton()
  self.anim.sprite:setPosition(self.window.position + 
    button:relativePosition() + self.displacement)
end

-- Shows sprite.
function ButtonCursor:show()
  self.anim.sprite:setVisible(true)
end

-- Hides sprite.
function ButtonCursor:hide()
  self.anim.sprite:setVisible(false)
end

-- Removes sprite.
function ButtonCursor:destroy()
  self.anim.sprite:removeSelf()
end

return ButtonCursor
