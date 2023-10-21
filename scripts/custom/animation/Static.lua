
-- ================================================================================================

--- Static sprite (not animated, no need for update).
---------------------------------------------------------------------------------------------------
-- @classmod Static
-- @extend Animation

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')

-- Class table.
local Static = class(Animation)

--- Overrides `Animation:update`.
-- Does nothing.
function Static:update()
end

return Static
