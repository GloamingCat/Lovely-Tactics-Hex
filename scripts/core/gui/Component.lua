
--[[===============================================================================================

Component
---------------------------------------------------------------------------------------------------
Base for a generic GUI component node.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')
local Vector = require('core/math/Vector')

local Component = class()

---------------------------------------------------------------------------------------------------
-- Initialize
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(position : Vector) The component's position relative to its parent.
-- @param(...) Aditional arguments passed to Component:createContent.
function Component:init(position, ...)
  self.visible = true
  self.content = List()
  self.position = position or Vector(0, 0, 0)
  self:createContent(...)
end
-- Creates child content.
function Component:createContent(...)
  -- Abstract.
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Updates child content.
function Component:update(...)
  for child in self.content:iterator() do
    if child.update then
      child:update(...)
    end
  end
end
-- Destroys child content.
function Component:destroy(...)
  for child in self.content:iterator() do
    if child.destroy then
      child:destroy(...)
    end
  end
  self.content:clear()
end

---------------------------------------------------------------------------------------------------
-- Visibility
---------------------------------------------------------------------------------------------------

-- Changes child content's visibility.
-- @param(value : boolean)
function Component:setVisible(value, ...)
  for child in self.content:iterator() do
    if child.setVisible then
      child:setVisible(value, ...)
    end
  end
  self.visible = value
end
-- Shows child content.
function Component:show(...)
  self:setVisible(true, ...)
end
-- Hides child content.
function Component:hide(...)
  self:setVisible(false, ...)
end
-- Updates child content position.
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
