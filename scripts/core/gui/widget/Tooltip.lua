
--[[===============================================================================================

Tooltip
---------------------------------------------------------------------------------------------------
The explanation text about a window or widget.

=================================================================================================]]

-- Imports
local SimpleText = require('core/gui/widget/SimpleText')
local Vector = require('core/math/Vector')

local Tooltip = class(SimpleText)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(window : Window) Parent window.
-- @param(term : string) Term key in the Vocab table.
-- @param(valign : string) The vertical alignment of the text (optional).
function Tooltip:init(window, term, valign)
  self.window = window
  local w = ScreenManager.width - window.GUI:windowMargin() * 2
  local h = ScreenManager.height - window.GUI:windowMargin() * 2
  SimpleText.init(self, '', Vector(-w/2, -h/2, -50), w, 'left', Fonts.gui_tooltip)
  self:setTerm('manual.' .. term, '')
  self:setAlign('left', valign or 'bottom')
  self:setMaxHeight(h)
  self:redraw()
  SimpleText.updatePosition(self)
end

---------------------------------------------------------------------------------------------------
-- Visibility
---------------------------------------------------------------------------------------------------

-- Overrides Component:update.
function Tooltip:update(dt)
  if GameManager:isMobile() and InputManager.keys["touch"]:isReleased() and self.window.open then
    self.visible = self:isActive(false)
    self.sprite:setVisible(self.visible)
  end
end
-- Overrides Component:setVisible.
-- Hides it if not active.
function Tooltip:setVisible(v)
  self.visible = v
  self.sprite:setVisible(v and self:isActive(true))
end
-- Shows it if active.
-- @param(x : number) Cursor x relative to window's center.
-- @param(y : number) Cursor y relative to window's center.
function Tooltip:onMove(x, y)
  if self.window.active then
    self.visible = self:isActive(self.window:isInside(x, y))
    self.sprite:setVisible(self.visible)
  end
end
-- Checks if the tooltip should be visible.
-- @param(insideWindow : boolean) Whether the cursor in inside the window or not.
function Tooltip:isActive(insideWindow)
  if GUIManager.disableTooltips then
    return false
  elseif GameManager:isMobile() then
    if self.window.fixedTooltip or self.window.cursor and self.window.cursor.visible then
      return true
    else
      return insideWindow and self.window.triggerPoint ~= nil
    end
  else
    return true
  end
end
-- Overrides Component:updatePosition.
-- Ignores.
function Tooltip:updatePosition(pos)
end

return Tooltip