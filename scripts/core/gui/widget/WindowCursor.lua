
-- ================================================================================================

--- A cursor for `GridWindow`s.
---------------------------------------------------------------------------------------------------
-- @uimod WindowCursor
-- @extend Component

-- ================================================================================================

-- Imports
local Component = require('core/gui/Component')
local Vector = require('core/math/Vector')

-- Class table.
local WindowCursor = class(Component)

-- ------------------------------------------------------------------------------------------------
-- Initialize
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GridWindow window Cursor's window.
function WindowCursor:init(window)
  self.window = window
  self.paused = false
  Component.init(self, Vector(0, window:cellHeight() / 2))
  window.content:add(self)
end
--- Implements `Component:setProperties`.
-- @implement
function WindowCursor:setProperties()
  self.hideOnDeactive = true
end
--- Overrides `Component:createContent`. Creates cursor sprite.
-- @override
function WindowCursor:createContent()
  self.anim = ResourceManager:loadAnimation(Config.animations.cursor, MenuManager.renderer)
  self.anim.sprite:setTransformation(self.anim.data.transform)
  self.anim.sprite:setVisible(false)
  local x, y, w, h = self.anim.sprite.quad:getViewport()
  self.position.x = -w / 2
  self.content:add(self.anim)
end

-- ------------------------------------------------------------------------------------------------
-- Content methods
-- ------------------------------------------------------------------------------------------------

--- Updates animation.
function WindowCursor:update(dt)
  if self.window.active and not self.paused then
    self.anim:update(dt)
  end
end
--- Updates position to the selected button.
function WindowCursor:updatePosition(wpos)
  local button = self.window:currentWidget()
  if button then
    local pos = button:relativePosition()
    pos:add(wpos)
    pos:add(self.position)
    self.anim.sprite:setPosition(pos)
  else
    self.anim.sprite:setVisible(false)
  end
end
--- Shows sprite.
function WindowCursor:setVisible(value)
  local active = not self.hideOnDeactive or self.window.active
  local visible = value and active and #self.window.matrix > 0
  Component.setVisible(self, visible)
  self.anim.sprite:setVisible(visible)
end

return WindowCursor
