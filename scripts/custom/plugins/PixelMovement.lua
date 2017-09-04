
local Player = require('core/objects/Player')

---------------------------------------------------------------------------------------------------
-- Pixel Movement
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Tries to move in a given angle.
-- @param(angle : number) the angle in degrees to move
-- @ret(boolean) returns false if the next angle must be tried
function Player:tryAngleMovement(angle)
  local dx, dy = math.angle2Coord(angle)
  dy = dy * tg
  local v = Vector(dx, -dy, 0)
  v:normalize()
  v.z = - v.y
  v:mul(self.speed * timer.getDelta())
  self:turnToVector(v.x, v.z)
  local p = self.position
  local collision = self:instantMoveTo(p.x + v.x, p.y + v.y, p.z + v.z)
  if collision == nil then
    self:playAnimation(self.walkAnimation)
    return true
  else
    return collision == 3
  end
end
