
--[[===============================================================================================

Rotatable
---------------------------------------------------------------------------------------------------
An object with rotation properties.
TODO

=================================================================================================]]

local Rotatable = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

function Rotatable:initRotation(r)
  r = r or 0
  self.rotation = r
  self.rotationSpeed = 0
  self.rotationOrig = r
  self.rotationDest = r
  self.rotationTime = 1
  self.rotationFiber = nil
  self.cropRotation = true
  self.interruptableRotation = true
end

function Rotatable:setRotation(r)
  self.rotation = r
end

---------------------------------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------------------------------

function Rotatable:updateRotation()
end

return Rotatable
