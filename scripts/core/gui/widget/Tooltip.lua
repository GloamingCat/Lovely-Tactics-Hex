
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
-- @tparam Window|Menu parent Parent window or menu.
-- @tparam string term Term key in the `Vocab` table.
-- @tparam[opt="left"] string valign The vertical alignment of the text.
-- @tparam[opt=0] number voffset The vertical offset from the alignment reference.
function Tooltip:init(parent, term, valign, voffset)
  if parent.menu then
    self.window = parent
    self.menu = parent.menu
  else
    self.menu = parent
  end
  valign = valign or 'bottom'
  voffset = voffset or 0
  local w = ScreenManager.width - self.menu:windowMargin() * 2
  local h = ScreenManager.height - self.menu:windowMargin() * 2
  local pos = Vector(-w/2, -h/2, -50)
  if valign ~= 'bottom' then
    pos.y = pos.y + voffset
  end
  TextComponent.init(self, '', pos, w, 'left', Fonts.menu_tooltip)
  self:setTerm(term, nil)
  self:setAlign('left', valign)
  self:setMaxHeight(h - voffset)
  self:redraw()
end
--- Overrides `TextComponent:setTerm`.
-- @override
function Tooltip:setTerm(term, fb)
  if not term or term == '' then
    TextComponent.setText(self, "")
  else
    TextComponent.setTerm(self, '{%manual.' .. term .. '}', fb or term)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Visibility
-- ------------------------------------------------------------------------------------------------

--- Overrides `Component:update`.
-- @override
function Tooltip:update(dt)
  if self.window and not self.window.open then
    return
  end
  if GameManager:isMobile() and InputManager.keys["touch"]:isReleased() then
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
  if not self.window then
    return
  end
  if self.window.active then
    self.visible = self:isActive(self.window:isInside(x, y))
    self.sprite:setVisible(self.visible)
  end
end
--- Checks if the tooltip should be visible.
-- @tparam boolean insideWindow Whether the cursor in inside the window or not.
-- @treturn boolean True if this tooltip is active.
function Tooltip:isActive(insideWindow)
  if not self.window then
    return true
  end
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
--- Overrides `ImageComponent:updatePosition`. Ignores window position.
-- @override
function Tooltip:updatePosition(pos)
  TextComponent.updatePosition(self, nil)
end

return Tooltip