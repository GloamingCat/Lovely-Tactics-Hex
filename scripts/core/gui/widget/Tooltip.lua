
-- ================================================================================================

--- The explanation text about a window or widget.
---------------------------------------------------------------------------------------------------
-- @uimod Tooltip

-- ================================================================================================

-- Imports
local TextComponent = require('core/gui/widget/TextComponent')
local Vector = require('core/math/Vector')

local Tooltip = class(TextComponent)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Window window Parent window.
-- @tparam string term Term key in the `Vocab` table.
-- @tparam[opt="left"] string valign The vertical alignment of the text.
function Tooltip:init(window, term, valign)
  self.window = window
  local w = ScreenManager.width - window.menu:windowMargin() * 2
  local h = ScreenManager.height - window.menu:windowMargin() * 2
  TextComponent.init(self, '', Vector(-w/2, -h/2, -50), w, 'left', Fonts.menu_tooltip)
  self:setTerm('manual.' .. term, '')
  self:setAlign('left', valign or 'bottom')
  self:setMaxHeight(h)
  self:redraw()
  TextComponent.updatePosition(self)
end

-- ------------------------------------------------------------------------------------------------
-- Visibility
-- ------------------------------------------------------------------------------------------------

--- Overrides `Component:update`.
-- @override
function Tooltip:update(dt)
  if GameManager:isMobile() and InputManager.keys["touch"]:isReleased() and self.window.open then
    self.visible = self:isActive(false)
    self.sprite:setVisible(self.visible)
  end
end
--- Overrides `Component:setVisible`. Hides it if not active.
-- @override
function Tooltip:setVisible(v)
  self.visible = v
  self.sprite:setVisible(v and self:isActive(true))
end
--- Shows it if active.
-- @tparam number x Cursor x relative to window's center.
-- @tparam number y Cursor y relative to window's center.
function Tooltip:onMove(x, y)
  if self.window.active then
    self.visible = self:isActive(self.window:isInside(x, y))
    self.sprite:setVisible(self.visible)
  end
end
--- Checks if the tooltip should be visible.
-- @tparam boolean insideWindow Whether the cursor in inside the window or not.
-- @treturn boolean
function Tooltip:isActive(insideWindow)
  if MenuManager.disableTooltips then
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
--- Overrides `Component:updatePosition`. Ignores window position.
-- @override
function Tooltip:updatePosition(pos)
end

return Tooltip