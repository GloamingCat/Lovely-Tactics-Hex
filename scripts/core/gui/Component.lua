
-- ================================================================================================

--- Base for a generic Menu component node.
---------------------------------------------------------------------------------------------------
-- @uimod Component

-- ================================================================================================

-- Imports
local List = require('core/datastruct/List')
local Vector = require('core/math/Vector')

-- Class table.
local Component = class()

-- ------------------------------------------------------------------------------------------------
-- Initialize
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Vector position The component's position relative to its parent.
-- @param ... Aditional arguments passed to Component:createContent.
function Component:init(position, ...)
  self.visible = true
  self.content = List()
  self.position = position or Vector(0, 0, 0)
  self:setProperties()
  self:createContent(...)
end
--- Sets general properties.
function Component:setProperties(...)
  -- Abstract.
end
--- Creates child content.
function Component:createContent(...)
  -- Abstract.
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Updates child content.
function Component:update(...)
  for child in self.content:iterator() do
    if child.update then
      child:update(...)
    end
  end
end
--- Destroys child content.
function Component:destroy(...)
  for child in self.content:iterator() do
    if child.destroy then
      child:destroy(...)
    end
  end
  self.content:clear()
end

-- ------------------------------------------------------------------------------------------------
-- Visibility
-- ------------------------------------------------------------------------------------------------

--- Changes child content's visibility.
-- @tparam boolean value
function Component:setVisible(value, ...)
  for child in self.content:iterator() do
    if child.setVisible then
      child:setVisible(value, ...)
    end
  end
  self.visible = value
end
--- Checks for visibility.
-- @treturn boolean
function Component:isVisible()
  return self.visible
end
--- Shows child content.
-- @coroutine
function Component:show(...)
  self:setVisible(true, ...)
end
--- Hides child content.
-- @coroutine
function Component:hide(...)
  self:setVisible(false, ...)
end
--- Refreshes content.
function Component:refresh()
  for child in self.content:iterator() do
    if child.refresh then
      child:refresh()
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Position
-- ------------------------------------------------------------------------------------------------

--- Sets the position relative to window's center.
-- @tparam number x Pixel x.
-- @tparam number y Pixel y.
-- @tparam number z Depth.
function Component:setRelativeXYZ(x, y, z)
  local pos = self.position
  pos.x = pos.x or x
  pos.y = pos.y or y
  pos.z = pos.z or z
end
--- Updates child content position.
function Component:updatePosition(parentPosition, ...)
  if parentPosition then
    parentPosition = parentPosition + self.position
  else
    parentPosition = self.position
  end
  for child in self.content:iterator() do
    if child.updatePosition then
      child:updatePosition(parentPosition, ...)
    end
  end
end

return Component
