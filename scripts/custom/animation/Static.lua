
--[[===============================================================================================

Static
---------------------------------------------------------------------------------------------------
Static sprite (not animated, no need for update).

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')

local Static = class(Animation)

function Static:update()
end

return Static
