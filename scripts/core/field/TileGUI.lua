
--[[===============================================================================================

TileGUI
---------------------------------------------------------------------------------------------------
ObjectTile graphics for battle interface.

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')

-- Alias
local tile2Pixel = math.field.tile2Pixel
local min = math.min

-- Constants
local tileW = Config.grid.tileW
local tileH = Config.grid.tileH

local TileGUI = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(tile : ObjectTile) The tile this object belongs to.
function TileGUI:init(tile, baseAnim, highlightAnim)
  local renderer = FieldManager.renderer
  local x, y, z = tile2Pixel(tile:coordinates())
  if baseAnim and Config.animations.tile >= 0 then
    local baseAnim = Database.animations[Config.animations.tile]
    self.baseAnim = ResourceManager:loadAnimation(baseAnim, renderer)
    self.baseAnim.sprite:setXYZ(x, y, z)
  end
  if highlightAnim and Config.animations.tileCursor >= 0 then
    local hlAnim = Database.animations[Config.animations.tileCursor]
    self.highlightAnim = ResourceManager:loadAnimation(hlAnim, renderer)
    self.highlightAnim.sprite:setXYZ(x, y, z)
  end
  self.x, self.y, self.h = tile:coordinates()
  self.grounded = FieldManager.currentField:isGrounded(tile:coordinates())
  self:hide()
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Updates graphics.
function TileGUI:update()
  if self.highlightAnim then
    self.highlightAnim:update()
  end
  if self.baseAnim then
    self.baseAnim:update()
  end
end
-- Erases any sprites.
function TileGUI:destroy()
  if self.baseAnim then
    self.baseAnim:destroy()
  end
  if self.highlightAnim then
    self.highlightAnim:destroy()
  end
end

---------------------------------------------------------------------------------------------------
-- Graphics
---------------------------------------------------------------------------------------------------

-- Updates graphics pixel depth according to the terrains' depth in this tile's coordinates.
function TileGUI:updateDepth()
  if not self.grounded then
    return
  end
  local layers = FieldManager.currentField.terrainLayers[self.h]
  local minDepth = layers[1].grid[self.x][self.y].depth
  for i = #layers, 2, -1 do
    minDepth = min(minDepth, layers[i].grid[self.x][self.y].depth)
  end
  if self.baseAnim then
    self.baseAnim.sprite:setOffset(nil, nil, minDepth)
  end
  if self.highlightAnim then
    self.highlightAnim.sprite:setOffset(nil, nil, minDepth - 1)
  end
end
-- Selects / deselects this tile.
-- @param(value : boolean) True to select, false to deselect.
function TileGUI:setSelected(value)
  if self.highlightAnim then
    self.highlightAnim.sprite:setVisible(value)
  end
end
-- Sets color to the color with the given label.
-- @param(name : string) Color label.
function TileGUI:setColor(name)
  self.colorName = name
  if name == nil or name == '' then
    name = 'nothing'
  end
  name = 'tile_' .. name
  if not self.selectable then
    name = name .. '_off'
  end
  local c = Color[name]
  self.baseAnim.sprite:setColor(c)
end

---------------------------------------------------------------------------------------------------
-- Show / Hide
---------------------------------------------------------------------------------------------------

-- Shows tile edges.
function TileGUI:show()
  if self.baseAnim then
    self.baseAnim.sprite:setVisible(self.grounded)
  end
end
-- Hides tile edges.
function TileGUI:hide()
  if self.baseAnim then
    self.baseAnim.sprite:setVisible(false)
  end
  self:setSelected(false)
end

return TileGUI

