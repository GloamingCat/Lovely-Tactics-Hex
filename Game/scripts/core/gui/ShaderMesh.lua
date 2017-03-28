
--[[===========================================================================

ShaderMesh
-------------------------------------------------------------------------------
A function that creates a new mesh from a sprite list.

=============================================================================]]

-- Imports
local ShaderAttribute = require('custom/ShaderAttribute')

-- Alias
local Mesh = love.graphics.newMesh

-- Contants
local shaderMeta = ShaderAttribute.sprite

return function(list)
  -- TODO
  local vertices = nil
  
  return Mesh(shaderMeta.meta, vertices)
end
