
-- ================================================================================================

--- Four arrows to navigate a GridWindow.
---------------------------------------------------------------------------------------------------
-- @uimod GridScroll
-- @extend Component

-- ================================================================================================

-- Imports
local Component = require('core/gui/Component')
local ImageComponent = require('core/gui/widget/ImageComponent')
local Vector = require('core/math/Vector')

-- Class table.
local GridScroll = class(Component)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GridWindow window Parent window.
function GridScroll:init(window)
  self.margin = 12
  Component.init(self, nil, window)
  window.content:add(self)
  self:setVisible(false)
end
--- Creates the scroll arrows, one for each direction.
function GridScroll:createContent(window)
  self.window = window
  self.arrows = {}
  local w = self.window.width / 2 + self.margin
  local h = self.window.height / 2 - self.window:paddingY()
  local pos = { Vector(w, 0, 0), Vector(0, h, 0), 
                Vector(0, -h, 0), Vector(-w, 0, 0) }
  local icon = {id = Config.animations.arrow}
  for i = 1, 4 do
    icon.col = (i - 1) % 2
    icon.row = (i - 1 - icon.col) / 2
    local sprite = ResourceManager:loadIcon(icon, MenuManager.renderer)
    self.arrows[i] = ImageComponent(sprite, pos[i])
    self.arrows[i].dx = 0
    self.arrows[i].dy = 0
    self.content:add(self.arrows[i])
  end
  self.right = self.arrows[1]
  self.right.dx = 1
  self.down = self.arrows[2]
  self.down.dy = 1
  self.up = self.arrows[3]
  self.up.dy = -1
  self.left = self.arrows[4]
  self.left.dx = -1
end

-- ------------------------------------------------------------------------------------------------
-- Position
-- ------------------------------------------------------------------------------------------------

--- Overrides `Component:update`. Updates scroll count.
-- @override
function GridScroll:update(dt)
  Component.update(self, dt)
  if self.horizontal then
    if InputManager.usingKeyboard then
      -- Use up-down arrows
      local w = self.window
      local row = w:actualRowCount() - w:rowCount()
      self.left:setVisible(false)
      self.right:setVisible(false)
      self.up:setVisible(w.offsetRow > 0)
      self.down:setVisible(w.offsetRow < row)
      self.horizontal = false
    end
  else
    if InputManager.mouse.active then
      -- Use left-right arrows
      local w = self.window
      local row = w:actualRowCount() - w:rowCount()
      self.left:setVisible(w.offsetRow > 0)
      self.right:setVisible(w.offsetRow < row)
      self.up:setVisible(false)
      self.down:setVisible(false)
      self.horizontal = true
    end
  end
  if self.speed then
    if self.count then
      local speed = self.speed * MenuManager.windowScroll * 2 / 100
      self.count = self.count + speed * dt
      if self.count >= 1 then
        self.count = 0
        self.window:nextWidget(self.dx or 0, self.dy or 0)
      end
    end
  end
end
--- Called when player moves the mouse.
-- @tparam number x Position x relative to the center of the window.
-- @tparam number y Position y relative to the center of the window.
function GridScroll:onMouseMove(x, y)
  local w = self.window
  local dy = 0
  if y <= -w:paddingY() and self.up:isVisible() then
    dy = -1
  elseif y >= w:paddingY() and self.down:isVisible() then
    dy = 1
  end
  if dy ~= 0 then
    self.count = self.count or 1
    self.dy = dy
  else
    self.count = nil
  end
end
--- Check if clicked on any of the arrows.
-- @tparam number px Pointer's x position.
-- @tparam number py Pointer's y position.
-- @treturn boolean Whether it advanced to the next page or not.
function GridScroll:onClick(px, py)
  px = px + self.window.position.x
  py = py + self.window.position.y
  for i = 1, #self.arrows do
    if self.arrows[i]:isVisible() then
      local x1, y1, x2, y2 = self.arrows[i].sprite:getBoundingBox()
      if px >= x1 and px <= x2 and py >= y1 and py <= y2 then
        self.window:nextPage(self.arrows[i].dx)
        return true
      end
    end
  end
  return false
end

-- ------------------------------------------------------------------------------------------------
-- Visibility
-- ------------------------------------------------------------------------------------------------

--- Overrides `Component:setVisible`. 
-- @override
function GridScroll:setVisible(value)
  Component.setVisible(self, value)
  if value then
    local w = self.window
    local row = w:actualRowCount() - w:rowCount()
    self.left:setVisible(w.offsetRow > 0 and InputManager.mouse.active)
    self.right:setVisible(w.offsetRow < row and InputManager.mouse.active)
    self.up:setVisible(w.offsetRow > 0 and not InputManager.mouse.active)
    self.down:setVisible(w.offsetRow < row and not InputManager.mouse.active)
    self.horizontal = InputManager.mouse.active
  end
end

return GridScroll
