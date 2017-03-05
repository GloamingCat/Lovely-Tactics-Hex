
local Animation = require('core/graphics/Animation')

--[[===========================================================================

Static sprite (not animated, no need for update).

=============================================================================]]

local Static = Animation:inherit()

function Static:update()
end

return Static
