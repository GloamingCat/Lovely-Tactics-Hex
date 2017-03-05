
local Mesh = love.graphics.newMesh
local shaderMeta = require('custom/ShaderAttribute').sprite

--[[===========================================================================

A function that creates a new mesh from a sprite list.

=============================================================================]]

return function(list)
  -- TODO
  local vertices = nil
  
  return Mesh(shaderMeta.meta, vertices)
end