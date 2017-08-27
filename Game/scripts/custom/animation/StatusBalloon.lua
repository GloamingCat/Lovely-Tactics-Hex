
--[[===============================================================================================

StatusBalloon
---------------------------------------------------------------------------------------------------
The balloon animation to show a battler's status.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')
local Sprite = require('core/graphics/Sprite')
local Animation = require('core/graphics/Animation')
local Balloon = require('custom/animation/Balloon')

-- Alias
local Image = love.graphics.newImage

-- Constants
local pph = Config.grid.pixelsPerHeight

local StatusBalloon = class(Balloon)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor. Initializes state and icon animation.
function StatusBalloon:init(...)
  Balloon.init(self, ...)
  self.state = 4
  self.statusIndex = 0
  self:initializeIcon()
  self.status = List()
  self.sprite:setCenterOffset()
  self:hide()
end
-- Creates the icon animation.
function StatusBalloon:initializeIcon()
  local sprite = Sprite(FieldManager.renderer)
  local anim = Animation(30, 1, 1, 1, 1, false, false, sprite)
  self:setIcon(anim)
end

---------------------------------------------------------------------------------------------------
-- Status
---------------------------------------------------------------------------------------------------

-- Adds a new status icon.
function StatusBalloon:addStatus(s)
  if not self.status:indexOf(s) then
    self.status:add(s)
  end
  if self.state == 4 then
    self:show()
    self.state = 0
  end
end
-- Removes status icon.
function StatusBalloon:removeStatus(s)
  local i = self.status:indexOf(s)
  self.status:remove(i)
  if self.status:isEmpty() then
    self:reset()
    self:hide()
    self.iconAnim:reset()
    self.iconAnim:hide()
    self.state = 4
  elseif self.statusIndex > i then
    self.statusIndex = self.statusIndex - 1
  end
end

---------------------------------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------------------------------

-- Overrides Balloon:update.
-- Considers state 4, when the character has no status.
function StatusBalloon:update()
  if not self.paused and self.state ~= 4 then
    Balloon.update(self)
  end
end
-- Overrides Balloon:onEnd.
-- Checks for status and changes the icon.
function StatusBalloon:onEnd()
  Balloon.onEnd(self)
  if self.state == 3 then
    self.statusIndex = math.mod1(self.statusIndex + 1, #self.status)
  elseif self.state == 1 then
    self.statusIndex = math.mod1(self.statusIndex, #self.status)
    local icon = self.status[self.statusIndex]
    self.iconAnim.sprite.texture = Image('images/' .. icon.imagePath)
    self.iconAnim.sprite:setQuad(icon.x, icon.y, icon.width, icon.height)
    self.iconAnim.sprite:setCenterOffset()
    self.iconAnim.quadWidth = icon.width
    self.iconAnim.quadHeight = icon.height
  end
end

---------------------------------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------------------------------

function StatusBalloon:updatePosition(char)
  local p = char.position
  self.sprite:setXYZ(p.x, p.y - char.colliderHeight * pph - 4, p.z)
  self.iconAnim.sprite:setPosition(self.sprite.position)
end

return StatusBalloon
